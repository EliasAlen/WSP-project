require 'sqlite3'

def get_ingredient_ids(ingredients)
    ingredient_ids = []
    ingredient_arr = ingredients.split(', ')
    db = SQLite3::Database.new("db/WSP-Project-vt_2024.db")
    db.results_as_hash = true
    ingredient_arr.each do |name|
        if db.execute("SELECT id FROM ingredients WHERE name = ?", name)[0] != nil
            ingredient_ids.append(db.execute("SELECT id FROM ingredients WHERE name = ?", name)[0])
        else 
            db.execute("INSERT INTO recipes name VALUES ?", name)
            ingredient_ids.append(db.execute("SELECT id FROM ingredients WHERE name = ?", name)[0])
        end
    end
    return ingredient_ids
end

p get_ingredient_ids("potato, tomato, celery")