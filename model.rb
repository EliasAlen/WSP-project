require 'sqlite3'

def connect_to_db(database)
    db = SQLite3::Database.new(database) 
    db.results_as_hash = true
    return db
end

# Returns nil upon failure
def create_recipe(user_id, name, difficulty, prep_time)
    db = connect_to_db("db/WSP-Project-vt_2024.db")
    if db.execute("SELECT * FROM recipes WHERE name = ?", name).first == nil && name != "" && prep_time.to_i.to_s == prep_time
        if difficulty == "beginner" || difficulty == "intermediate" || difficulty == "advanced"
            db.execute("INSERT INTO recipes (name, difficulty, prep_time, creator_id) VALUES (?, ?, ?, ?)", name, difficulty, prep_time.to_i, user_id)
        else
            nil
        end
    else
        nil
    end
end

def correct_ingredient_format(ingredients)
    
    ingredient_amount_arr = ingredients.split(', ')
    i = 0
    while i < ingredient_amount_arr.length
        temp_arr = ingredient_amount_arr[i].split(' ')
        if temp_arr.length < 2 || temp_arr[0].to_i <= 0
            return false
        end
        i += 1
    end
    return true
end

p correct_ingredient_format("1dl mjöl, 3dl socker, 2dl mjölk")

def save_ingredient_info(ingredients, recipe_name)
    ingredient_ids = []
    amount_arr = []
    ingredient_arr = []

    ingredient_amount_arr = ingredients.split(', ')
    i = 0
    while i < ingredient_amount_arr.length
        temp_arr = ingredient_amount_arr[i].split(' ')
        amount_arr.append(temp_arr[0])
        ingredient_arr.append(temp_arr[1..].join(" "))
        i += 1
    end

    db = connect_to_db("db/WSP-Project-vt_2024.db")
    ingredient_arr.each do |name|
        if db.execute("SELECT id FROM ingredients WHERE name = ?", name).first == nil
            db.execute("INSERT INTO ingredients (name) VALUES (?)", name)
            ingredient_ids.append(db.execute("SELECT id FROM ingredients WHERE name = ?", name).first["id"])
        else 
            ingredient_ids.append(db.execute("SELECT id FROM ingredients WHERE name = ?", name).first["id"])
        end
    end

    recipe_id = db.execute("SELECT id FROM recipes WHERE name = ?", recipe_name)
    i = 0
    while i < ingredient_ids.length
        db.execute("INSERT INTO recipe_ingredient_relation (ingredient_id, amount, recipe_id) VALUES (?, ?, ?)", ingredient_ids[i], amount_arr[i], recipe_id.first["id"])
        i += 1
    end   
end

def ingredients_to_s(recipe_id)
    ingredient_arr = []
    db = connect_to_db("db/WSP-Project-vt_2024.db")
    temp_arr = db.execute("SELECT * FROM recipe_ingredient_relation WHERE recipe_id = ?", recipe_id)
    temp_arr.each do |ingredient|
        ingredient_arr.append("#{ingredient[1]} #{db.execute("SELECT name FROM ingredients WHERE id = ?", ingredient[2]).first["name"]}")
    end
    ingredient_str = ingredient_arr.join(", ")
    return ingredient_str
end

def update_ingredients(ingredients, recipe_name)
    ingredient_ids = []
    amount_arr = []
    ingredient_arr = []

    ingredient_amount_arr = ingredients.split(', ')
    i = 0
    while i < ingredient_amount_arr.length
        temp_arr = ingredient_amount_arr[i].split(' ')
        amount_arr.append(temp_arr[0])
        ingredient_arr.append(temp_arr[1..].join(" "))
        i += 1
    end

    db = connect_to_db("db/WSP-Project-vt_2024.db")
    ingredient_arr.each do |name|
        if db.execute("SELECT id FROM ingredients WHERE name = ?", name)[0] == nil
            db.execute("INSERT INTO ingredients (name) VALUES (?)", name)
            ingredient_ids.append(db.execute("SELECT id FROM ingredients WHERE name = ?", name).first["id"])
        else 
            ingredient_ids.append(db.execute("SELECT id FROM ingredients WHERE name = ?", name).first["id"])
        end
    end
    recipe_id = db.execute("SELECT id FROM recipes WHERE name = ?", recipe_name)
    db.execute("DELETE FROM recipe_ingredient_relation WHERE recipe_id = ?", recipe_id.first["id"])

    i = 0
    while i < ingredient_ids.length
        db.execute("INSERT INTO recipe_ingredient_relation (ingredient_id, amount, recipe_id) VALUES (?, ?, ?)", ingredient_ids[i], amount_arr[i], recipe_id.first["id"])
        i += 1
    end  
end

def ingredients_to_ids(ingredients)
    db = connect_to_db("db/WSP-Project-vt_2024.db")
    ingredient_arr = ingredients.split(', ')
    ids = []

    ingredient_arr.each do |ingredient|
        ids.append(db.execute("SELECT id FROM ingredients WHERE name = ?", ingredient).first["id"])
    end
    return ids
end

def process_recipe_hash()
    db = connect_to_db("db/WSP-Project-vt_2024.db")
    temp_arr = db.execute("SELECT * FROM recipe_ingredient_relation")
    already_checked = []
    recipies_and_ingredients = []
    temp_arr.each do |index|
        if !already_checked.include?(index["recipe_id"])
            already_checked.append(index["recipe_id"])
            recipies_and_ingredients.append([index["recipe_id"], [index["ingredient_id"]]])
        else
            i = 0
            while i < recipies_and_ingredients.length
                if recipies_and_ingredients[i][0] == index["recipe_id"]
                    recipies_and_ingredients[i][1].append(index["ingredient_id"])
                    break
                end
                i += 1
            end
        end
    end
    return recipies_and_ingredients
end

def select_recipes_w_ingredients(ingredient_ids)
    db = connect_to_db("db/WSP-Project-vt_2024.db")
    recipe_list = process_recipe_hash()
    ingredient_ids.each do |ingredient|
        i = 0
        while i < recipe_list.length
            if !recipe_list[i][1].include?(ingredient)
                recipe_list.delete_at(i)
                i -= 1
            end
            i += 1
        end
    end
    filtered_recipes_as_hash = []
    recipe_list.each do |recipe_id|
        filtered_recipes_as_hash.append(db.execute("SELECT * FROM recipes WHERE id = ?", recipe_id[0])[0])
    end
    return filtered_recipes_as_hash
end

def translate_to_route(string)
    route = string.sub(", ", "&")
    return route
end

def extract_from_route(route)
    string = route.sub("&", ", ")
    return string
end

def save_user_info(username, pwdigest, is_admin)
    db = connect_to_db("db/WSP-Project-vt_2024.db")
    db.execute("INSERT INTO users (username, pwdigest, is_admin) VALUES (?, ?, ?)", username, pwdigest, is_admin)
end

def get_data(table, search_term, value)
    db = connect_to_db("db/WSP-Project-vt_2024.db")
    return db.execute("SELECT * FROM #{table} WHERE #{search_term} = ?",value).first
end

def get_all_data(table)
    db = connect_to_db("db/WSP-Project-vt_2024.db")
    return db.execute("SELECT * FROM #{table}")
end

def delete_recipe(id)
    db = connect_to_db("db/WSP-Project-vt_2024.db")
    db.execute("DELETE FROM recipes WHERE id = ?", id)
    db.execute("DELETE FROM recipe_ingredient_relation WHERE recipe_id = ?", id)
    db.execute("DELETE FROM user_recipe_relation WHERE recipe_id = ?", id)
end

def delete_user(id)
    db = connect_to_db("db/WSP-Project-vt_2024.db")
    db.execute("DELETE FROM users WHERE id = ?", id)
    db.execute("DELETE FROM user_recipe_relation WHERE user_id = ?", id)
    db.execute("DELETE FROM recipes WHERE creator_id = ?", id)
end

def save_recipe(user_id, recipe_id)
    db = connect_to_db("db/WSP-Project-vt_2024.db") 
    db.execute("INSERT INTO user_recipe_relation (user_id, recipe_id) VALUES (?, ?)", user_id, recipe_id)
end

def is_saved(user_id, recipe_id)
    db = connect_to_db("db/WSP-Project-vt_2024.db")
    return db.execute("SELECT * FROM user_recipe_relation WHERE user_id = ? AND recipe_id = ?", user_id, recipe_id).first !=nil
end

def remove_recipe(user_id, recipe_id)
    db = connect_to_db("db/WSP-Project-vt_2024.db")
    db.execute("DELETE FROM user_recipe_relation WHERE user_id = ? AND recipe_id = ?", user_id, recipe_id)
end

def get_saved_recipes(user_id)
    recipes = []
    db = connect_to_db("db/WSP-Project-vt_2024.db")
    result = db.execute("SELECT * FROM user_recipe_relation WHERE user_id = ?", user_id)
    result.each do |recipe|
        recipes.append(db.execute("SELECT * FROM recipes WHERE id = ?", recipe["recipe_id"]).first)
    end
    return recipes
end

def is_creator(user_id, recipe_id)
    db = connect_to_db("db/WSP-Project-vt_2024.db")
    return db.execute("SELECT * FROM recipes WHERE creator_id = ? AND id = ?", user_id, recipe_id).first != nil
end

def get_user_list()
    db = connect_to_db("db/WSP-Project-vt_2024.db")
    return db.execute("SELECT * FROM users")
end

def update_data(name, difficulty, prep_time, id)
    db = connect_to_db("db/WSP-Project-vt_2024.db")
    db.execute("UPDATE recipes SET name = ?, difficulty = ?, prep_time = ? WHERE id = ?", name, difficulty, prep_time, id)
end

def username_occupied(username)
    db = connect_to_db("db/WSP-Project-vt_2024.db")
    return db.execute("SELECT * FROM users WHERE username = ?", username).first != nil
end

p get_data("users", "username", "gra")