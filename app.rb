require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require_relative './model.rb'



get('/')  do
  slim(:start)
end 

get('/recipes_browse') do
  db = SQLite3::Database.new("db/WSP-Project-vt_2024.db")
  db.results_as_hash = true
  @result = db.execute("SELECT * FROM recipes")

  slim(:"recipes_browse/index")
end

get('/recipes_browse/new') do
  slim(:"recipes_browse/new")
end

post('/recipes_browse/:id/delete') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/WSP-Project-vt_2024.db") 
  db.execute("DELETE FROM recipes WHERE AlbumId = ?", id)
  redirect('/recipes_browse')
end

post('/recipes_browse/new') do
  name = params[:name]
  ingredients = params[:ingredients]
  difficulty = params[:difficulty]
  prep_time = params[:prep_time]
  db = SQLite3::Database.new("db/WSP-Project-vt_2024.db") 
  p name, difficulty, prep_time
  db.execute("INSERT INTO recipes (name, difficulty, prep_time) VALUES (?, ?, ?)", name, difficulty, prep_time.to_i)
  ingredient_ids = get_ingredient_ids(ingredients)
  insert_ingredients_to_recipe(ingredient_ids, name)
  redirect('/recipes_browse')
end

post('/recipes_browse/:id/update') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/WSP-Project-vt_2024.db") 
  db.execute("UPDATE recipes SET name = ?, IgredientId = ? WHERE id = ?",params[:title] ,params[:artist_id], id)
  redirect('/recipes_browse')
end

get('/recipes_browse/:id/edit') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/WSP-Project-vt_2024.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM albums WHERE AlbumId = ?",id).first
  slim(:"/recipes_browse/edit", locals:{result:result})
end

get('/recipes_browse/:id') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/WSP-Project-vt_2024.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM albums WHERE AlbumId = ?",id).first
  result2 = db.execute("SELECT Name FROM artists WHERE ArtistId IN (SELECT ArtistId FROM albums WHERE AlbumId = ?)",id).first
  p result2
  slim(:"recipes_browse/show",locals:{result:result,result2:result2})
end