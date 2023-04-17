import requests
from flask import Flask, jsonify

app = Flask(__name__)


@app.route('/<user>/<repo>', methods=['GET'])
def get_latest_release(user, repo):
    release_url = f'https://api.github.com/repos/{user}/{repo}/releases/latest'
    release_response = requests.get(release_url)
    if release_response.status_code != 200:
        return jsonify({'error': 'Release not found.'}), 404

    release_data = release_response.json()
    version = release_data['tag_name']
    return jsonify({'version': version})


if __name__ == '__main__':
    app.run(port=8080)
