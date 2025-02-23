#Setup Database
python -m database.query_upload  --path "database\\db_teardown.sql"
python -m database.query_upload  --path "database\\db_design.sql"


#Uploading (Participant Split (iMessage, Instagram, Discord) Files)
python -m setup.upload --path "data\Discord"
python -m setup.upload --path "data\\Instagram\\your_instagram_activity\\messages\\inbox"
python -m setup.upload --path "data\\Message"

#Uploading (Time Split --> Participant Split (Call) Files)
python restructuring\\join_files_call.py --input "data\\Call" --output "data\\joined_calls.csv"
python restructuring\\split_file_call.py --input "data\\joined_calls.csv" --output "data\\participant_split_calls"
python -m setup.upload --path "data\\participant_split_calls"

#Uploading Contacts (Optional)
python -m database.generate_super --contacts "credentials\personal_contact.json"


#Removing 
python -m database.query_upload --path "database\\cleaning\\filter_noise.sql"
python -m database.query_upload --path "database\\cleaning\\interpolate_unknown.sql"

python -m database.query_upload --path "database\\cleaning\\split_interparticipant_calls.sql"




python -m database.query_upload --path "analysis\\generate_metrics_1.sql"


#SELECT communication_type, TEMP_SUPER_ROOM, TEMP_SUPER_PARTICIPANT, time_sent, time_ended, m1_previous, m2_continue, m3_response from communication order by temp_super_room, time_sent




