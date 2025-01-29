


python upload.py --path "C:\\Users\\ldunc\\OneDrive\\Documents\\__INNER\\new_data(2025-01-21)\Discord"
python upload.py --path "C:\\Users\\ldunc\\OneDrive\\Documents\\__INNER\\new_data(2025-01-21)\\Instagram\\your_instagram_activity\\messages\\inbox"
python upload.py --path "C:\\Users\\ldunc\\OneDrive\\Documents\\__INNER\\new_data(2025-01-21)\\Messages"


python file_preprocessing\\combine_files.py --input "C:\\Users\\ldunc\\OneDrive\\Documents\\__INNER\\new_data(2025-01-21)\\Calls" --output "data\\joined_calls.csv"
python file_preprocessing\\split_multi.py --input "data\\joined_calls.csv" --output "data\\person_calls"
python upload.py --path "data\\person_calls"



python -m database.db_support --function upload_contact --contact "personal_contact.json"
python -m database.db_support --function clear_directional

