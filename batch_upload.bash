#NOTE: assumes db created, with matching creds in "db_creds.json"

#Upload Data (Instagram + Discord + Message: stored by participants)
python upload.py --path "C:\\Users\\ldunc\\OneDrive\\Documents\\__INNER\\new_data(2025-01-21)\Discord"
python upload.py --path "C:\\Users\\ldunc\\OneDrive\\Documents\\__INNER\\new_data(2025-01-21)\\Instagram\\your_instagram_activity\\messages\\inbox"
python upload.py --path "C:\\Users\\ldunc\\OneDrive\\Documents\\__INNER\\new_data(2025-01-21)\\Messages"

#Upload Data (Call: stored by date)
#TODO: combine all participant data together, split by participant, then upload
python file_processing\\combine_files.py --input "C:\\Users\\ldunc\\OneDrive\\Documents\\__INNER\\new_data(2025-01-21)\\Calls" --output "data\\joined_calls.csv"
python file_processing\\split_multi.py --input "data\\joined_calls.csv" --output "data\\person_calls"
python upload.py --path "data\\person_calls"

#NOTE: uploading contacts is optional for cases, where major communications occur
python -m file_processing.upload_contact --input "personal_contact.json"

#NOTE: add your formats here
