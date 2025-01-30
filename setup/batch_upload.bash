

#Uploading (Participant Split (iMessage, Instagram, Discord) Files)
python upload.py --path "data\Discord"
python upload.py --path "data\\Instagram\\your_instagram_activity\\messages\\inbox"
python upload.py --path "data\\Message"

#Uploading (Time Split --> Participant Split (Call) Files)
python multi_to_single_preprocessing\\join_files_call.py --input "data\\Call" --output "data\\joined_calls.csv"
python multi_to_single_preprocessing\\split_file_call.py --input "data\\joined_calls.csv" --output "data\\participant_split_calls"
python upload.py --path "data\\participant_split_calls"


#Uploading Contacts (Super Participants)
python -m database.db_support --function upload_contact --contact "credentials/personal_contact.json"

#Remove Spam (One Sided)
python -m database.db_support --function clear_directional

#Create Weights
python -m database.db_support --function set_weights

#Defining Unique Instances For Analysis (Super Room)
python -m database.db_support --function generate_super_rooms

