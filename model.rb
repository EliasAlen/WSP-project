require 'sqlite3'

def get_ingredient_ids(ingredients)
    ingredient_ids = []
    ingredient_arr = ingredients.split(', ')
    db = SQLite3::Database.new("db/WSP-Project-vt_2024.db")
    db.results_as_hash = true
    ingredient_arr.each do |name|
        if db.execute("SELECT id FROM ingredients WHERE name = ?", name)[0] == nil
            db.execute("INSERT INTO ingredients (name) VALUES (?)", name)
            ingredient_ids.append(db.execute("SELECT id FROM ingredients WHERE name = ?", name).first["id"])
        else 
            ingredient_ids.append(db.execute("SELECT id FROM ingredients WHERE name = ?", name).first["id"])
        end
    end
    p ingredient_ids
    return ingredient_ids
end

def insert_ingredients_to_recipe(id_arr, recipe_name)
    db = SQLite3::Database.new("db/WSP-Project-vt_2024.db")
    db.results_as_hash = true
    recipe_id = db.execute("SELECT id FROM recipes WHERE name = ?", recipe_name)
    id_arr.each do |id|
        db.execute("INSERT INTO recipe_ingredient_relation (ingredient_id, recipe_id) VALUES (?, ?)", id, recipe_id.first["id"])
    end
    # return db.execute("SELECT ingredient_id FROM recipe_ingredient_relation WHERE recipe_id = ?", recipe_id)
end