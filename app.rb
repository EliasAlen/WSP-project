require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

#gör användarinformation och adminkontroll lättare för övriga routes
#
before('/*') do
  @user_info = get_data("users", "id", session[:id])
  if session[:id] != nil
    if @user_info["is_admin"] == 1
      @is_admin = true
    else
      @is_admin = false
    end
  end
end

#ser till att användaren är inloggad för att komma åt user relaterade routes
#
before('/user/*') do
  if session[:id] == nil
    redirect('/login')
  end
end

#ser till att användaren är admin för att komma åt admin relaterade routes
#
before('/admin/*') do
  if @user_info["is_admin"] != 1
    redirect('/login')
  end
end

#visar landing page
#
get('/')  do
  slim(:start)
end 

#visar en lista av alla recept i databasen
#
get('/recipes_browse') do
  @result = get_all_data("recipes")
  slim(:"recipes_browse/index")
end

#filtrerar bort recept som inte innehåller specifika ingredienser
#
#@params [String] must_contain, filtrerings specifikationerna
post('/recipes_browse') do
  ingredient = translate_to_route(params[:ingredient])
  redirect("/recipes_browse/#{ingredient}")
end

#tar bort filtreringar av receptlista
#
post('/recipes_browse/reset_filter') do
  redirect("/recipes_browse")
end

#meny för att lägga in ett nytt recept i databasen
#
get('/recipes_browse/new') do
  slim(:"recipes_browse/new")
end

#tar bort recept från databas
#
#@params [integer] id, idt för receptet som ska tas bort
post('/recipes_browse/recipe/:id/delete') do
  id = params[:id].to_i
  if is_creator(session[:id], id)
    delete_recipe(id)
    redirect('/recipes_browse')
  else
    slim(:error)
  end
end

#Sparar recept till användare
#
#@params [integer] user_id, id för användare som är inloggad
#@params [integer] recipe_id, receptets id
post('/recipes_browse/recipe/:id/save') do
  id = params[:id].to_i
  if session[:id] != nil
    save_recipe(session[:id], id)
    redirect('/recipes_browse')
  else
    slim(:error)
  end
end

#tar bort receptet från listan av sparade recept
#
#@params [integer] user_id, id för användare som är inloggad
#@params [integer] recipe_id, receptets id
post('/recipes_browse/recipe/:id/saved/delete') do
  id = params[:id].to_i
  if session[:id] != nil
    remove_recipe(session[:id], id)
    redirect('/recipes_browse')
  else
    slim(:error)
  end
end

#skapar ett nytt recept utifrån given information
#
#@params [string] name, namnet på receptet
#@params [string] ingredients, ingredienserna som receptet innehåller och i vilken mängd
#@params [string] difficulty, svårhetsgrad av receptet
#@params [integer] prep_time, hur lång tid receptet tar att tillaga i minuter
post('/recipes_browse/create') do
  if session[:id] != nil
    name = params[:name]
    ingredients = params[:ingredients]
    difficulty = params[:difficulty]
    prep_time = params[:prep_time]
    if create_recipe(session[:id], name, difficulty, prep_time) == nil || !correct_ingredient_format()
      slim(:error)
    else
      create_recipe(session[:id], name, difficulty, prep_time)
      save_ingredient_info(ingredients, name)
      redirect('/recipes_browse')
    end
  else
    redirect('/login')
  end
end

#uppdaterar info om ett recept
#
#@params [string] name, namnet på receptet
#@params [string] ingredients, ingredienserna som receptet innehåller och i vilken mängd
#@params [string] difficulty, svårhetsgrad av receptet
#@params [integer] prep_time, hur lång tid receptet tar att tillaga i minuter
post('/recipes_browse/recipe/:id/update') do
  id = params[:id].to_i
  if is_creator(session[:id], id)
    name = params[:name]
    difficulty = params[:difficulty]
    prep_time = params[:prep_time]
    ingredients = params[:ingredients]
    update_data(name, difficulty, prep_time, id)
    update_ingredients(ingredients, name)
    redirect('/recipes_browse')
  else
    slim(:error)
  end
end

#route för att ändra info om ett recept
#
get('/recipes_browse/recipe/:id/edit') do
  id = params[:id].to_i
  @result = get_data("recipes", "id", id)
  @ingredients = ingredients_to_s(id)
  slim(:"recipes_browse/edit")
end

#visar info om givet recept
#
#@params [integer] id, id för receptet som ska visas
get('/recipes_browse/recipe/:id') do
  id = params[:id].to_i
  @result = get_data("recipes", "id", id)
  @ingredients = ingredients_to_s(id)
  slim(:"recipes_browse/show")
end

#
get('/recipes_browse/:filter_ingredients') do
  @ingredients = extract_from_route(params[:filter_ingredients])
  ingredient_ids = ingredients_to_ids(@ingredients)
  @result = select_recipes_w_ingredients(ingredient_ids)
  
  slim(:"recipes_browse/index")
end

get('/register') do
  slim(:register)
end

post('/register') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
  if !username_occupied(username)
    if password == password_confirm
      pwdigest = BCrypt::Password.create(password)
      save_user_info(username, pwdigest, 0)
      redirect('/')
    else
      slim(:error)
    end
  else
    slim(:error)
  end
end

get('/login') do
  slim(:login)
end

login_requests = {}
post('/login') do

  if login_requests[request.ip] != nil
    if Time.now - login_requests[request.ip] < 10
      return slim(:error)
    end
  end 

  p login_requests[request.ip]
  login_requests[request.ip] = Time.now

  username = params[:username]
  password = params[:password]
  result = get_data("users", "username", username)
  if result == nil
    slim(:error)
  else
    pwdigest = result["pwdigest"]
    id = result["id"]

    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      redirect('/')
    else
      slim(:error)
    end
  end
end

post('/log_out') do
  session[:id] = nil
  redirect('/')
end

get('/user/saved_recipes') do
  @result = get_saved_recipes(session[:id])
  slim(:your_recipes)
end

post('/user/saved_recipes/:id/delete') do
  id = params[:id].to_i
  if is_creator(session[:id], id)
    remove_recipe(session[:id], id)
    redirect('/user/saved_recipes')
  else
    redirect('/login')
  end
end

get('/admin/manage_users') do
  @result = get_user_list()
  slim(:user_management)
end

post('/admin/manage_users/:id/delete') do
  if @is_admin
    user_id = params[:id]
    delete_user(user_id)
    redirect('/admin/manage_users')
  else
    slim(:error)
  end
end