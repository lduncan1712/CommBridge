

#Uploading (Participant Split (iMessage, Instagram, Discord) Files)
python -m setup.upload --path "data\Discord"
python -m setup.upload --path "data\\Instagram\\your_instagram_activity\\messages\\inbox"
python -m setup.upload --path "data\\Message"

#Uploading (Time Split --> Participant Split (Call) Files)
python multi_to_single_preprocessing\\join_files_call.py --input "data\\Call" --output "data\\joined_calls.csv"
python multi_to_single_preprocessing\\split_file_call.py --input "data\\joined_calls.csv" --output "data\\participant_split_calls"
python -m setup.upload --path "data\\participant_split_calls"


#Uploading Contacts (Super Participants)
python -m database.query_upload --path upload_contact --contact "credentials/personal_contact.json"


#Remove Span (IE: randoms calling)
python -m database.query_upload --path "database/query_remove_spam.sql"


#Generate Super Rooms:
python -m database.query_upload --path database/query_set_participant_list.sql
python -m database.query_upload --path database/query_set_super_participant_list.sql
python -m database.query_upload --path database/query_set_super_rooms.sql


#Set Communication Weights
python -m database.query_upload --path "database/query_set_communication_weight.sql"


