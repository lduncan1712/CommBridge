#Setup Database
python -m database.query_upload  --path "database\\db_teardown.sql"
python -m database.query_upload  --path "database\\db_creation.sql"


#Uploading (Participant Split (iMessage, Instagram, Discord) Files)
python -m setup.upload --path "data\Discord"
python -m setup.upload --path "data\\Instagram\\your_instagram_activity\\messages\\inbox"
python -m setup.upload --path "data\\Message"

#Uploading (Time Split --> Participant Split (Call) Files)
python multi_to_single_preprocessing\\join_files_call.py --input "data\\Call" --output "data\\joined_calls.csv"
python multi_to_single_preprocessing\\split_file_call.py --input "data\\joined_calls.csv" --output "data\\participant_split_calls"
python -m setup.upload --path "data\\participant_split_calls"

#Uploading Contacts (Optional)
python -m database.build_super --contacts "credentials\personal_contact.json"


#Removing 
python -m database.query_upload --path "database\\queries\\filter_noise.sql"
python -m database.query_upload --path "database\\\queries\\interpolate_unknown.sql"


python -m database.query_upload --path "database\\queries\\tabulate_deltas.sql"







