from flask import Blueprint


blueprint = Blueprint('pr_suivi_flore_territoire', __name__)

@blueprint.route('/', methods=['GET'])
def test():
    return 'ça marche'