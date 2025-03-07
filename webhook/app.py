from flask import Flask, request, Response
import hmac
import hashlib
import subprocess
import os

app = Flask(__name__)

# Replace with your secret from GitHub
WEBHOOK_SECRET = os.environ.get('WEBHOOK_SECRET')

if not WEBHOOK_SECRET:
    raise ValueError("WEBHOOK_SECRET environment variable is not set")


def is_valid_signature(payload_body, signature_header):
    if not signature_header:
        return False

    # Get expected signature
    expected_signature = hmac.new(
        key=WEBHOOK_SECRET.encode(),
        msg=payload_body,
        digestmod=hashlib.sha256
    ).hexdigest()

    # Compare signatures
    return hmac.compare_digest(
        f'sha256={expected_signature}',
        signature_header
    )


def deploy():
    # Path to your deployment script
    deploy_script = '/opt/kknds_wiki/webhook/deploy.sh'

    try:
        # Make sure the script is executable
        os.chmod(deploy_script, 0o755)

        # Run the deployment script
        result = subprocess.run(
            ['bash', deploy_script],
            capture_output=True,
            text=True
        )

        if result.returncode == 0:
            return True, result.stdout
        else:
            return False, result.stderr

    except Exception as e:
        return False, str(e)


@app.route('/webhook', methods=['POST'])
def webhook():

    # Get X-Hub-Signature-256 header
    signature_header = request.headers.get('X-Hub-Signature-256')

    # Verify the signature
    if not is_valid_signature(request.get_data(), signature_header):
        return Response('Invalid signature', status=403)

    # Parse the JSON payload
    event = request.json

    # Check if it's a push event
    if request.headers.get('X-GitHub-Event') == 'push':
        # Deploy the changes
        success, message = deploy()

        if success:
            return Response(f'Deployed successfully: {message}', status=200)
        else:
            return Response(f'Deployment failed: {message}', status=500)

    return Response('Event received but no action taken', status=200)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=4000)