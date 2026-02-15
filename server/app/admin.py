from sqladmin import Admin, ModelView
from .models import User, Friend, Activity, ActivityReaction, RevokedToken

class UserAdmin(ModelView, model=User):
    column_list = [User.id, User.email, User.username, User.first_name, User.last_name, User.is_admin]

class FriendAdmin(ModelView, model=Friend):
    column_list = [Friend.user_id, Friend.friend_id, Friend.created_at]

class ActivityAdmin(ModelView, model=Activity):
    column_list = [Activity.actor_user_id, Activity.type, Activity.created_at, Activity.expires_at]

class ActivityReactionAdmin(ModelView, model=ActivityReaction):
    column_list = [ActivityReaction.activity_id, ActivityReaction.user_id, ActivityReaction.reaction]

class RevokedTokenAdmin(ModelView, model=RevokedToken):
    column_list = [RevokedToken.jti, RevokedToken.user_id, RevokedToken.expires_at]

def setup_admin(app, engine):
    admin = Admin(app, engine, title="Database")
    admin.add_view(UserAdmin)
    admin.add_view(FriendAdmin)
    admin.add_view(ActivityAdmin)
    admin.add_view(ActivityReactionAdmin)
    admin.add_view(RevokedTokenAdmin)
