from flask import Blueprint, request, session, current_app

from geonature.utils.errors import InsufficientRightsError
from pypnusershub.db.tools import get_or_fetch_user_cruved

def check_user_cruved_visit(user, visit, cruved_level):
    """
    Check if user have right on a visit object, related to his cruved
    if not, raise 403 error
    """
    
    is_allowed = False
    if cruved_level == '1':
        
        for role in visit.observers:
            if role.id_role == user.id_role:
                print('même id ')
                is_allowed = True
                break
            elif visit.id_digitiser == user.id_role:
                is_allowed = True
                break
        if not is_allowed:
            raise InsufficientRightsError(
            ('User "{}" cannot update visit number {} ')
            .format(user.id_role, visit.id_base_visit),
            403
            )       
       
       
    elif cruved_level == '2':
         for role in visit.observers:
            if role.id_role == user.id_role:
                print('même role')
                is_allowed = True
                break
            elif visit.id_digitiser == user.id_role:
                is_allowed = True
                break
            elif role.id_organisme == user.id_organisme:
                is_allowed = True
                break
         if not is_allowed:
            raise InsufficientRightsError(
            ('User "{}" cannot update visit number {} ')
            .format(user.id_role, visit.id_base_visit),
            403
            )   
    
   

