import firebase_admin
from firebase_admin import credentials
from firebase_admin import auth

cred = credentials.Certificate('config/firebase.json')
default_app = firebase_admin.initialize_app(cred)

uid = '114113024042054518217'
custom_token = auth.create_custom_token(uid)

print("Bearer " + custom_token)