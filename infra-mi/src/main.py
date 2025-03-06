from fastapi import FastAPI, APIRouter, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import subprocess
import os

app = FastAPI()
router = APIRouter()

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Paths to the shell scripts
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SCRIPT_PATH_GIT = os.path.join(SCRIPT_DIR, "scripts/git-commands.sh")
SCRIPT_PATH_INIT = os.path.join(SCRIPT_DIR, "scripts/initial-setup.sh")
SCRIPT_PATH_PROD = os.path.join(SCRIPT_DIR, "scripts/prod-git-commands.sh")

# Pydantic model for request validation
class Payload(BaseModel):
    user: str
    project_name: str
    repo_name: str
    action: str

# Helper function to run shell scripts
def run_script(script_path: str, args: list[str]) -> None:
    try:
        process = subprocess.Popen(["bash", script_path, *args], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = process.communicate()
        if process.returncode != 0:
            raise Exception(f"Script failed: {stderr.decode().strip()}")
        print(stdout.decode().strip())
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Run initial setup script
def initial_setup(namespace: str, app_name: str, repo_name: str):
    run_script(SCRIPT_PATH_INIT, [namespace, app_name, repo_name])

# Run deploy
def run_deploy(repo_name: str, namespace: str):
    run_script(SCRIPT_PATH_PROD, [repo_name, namespace])

# Run Git commands script
def git_commands(repo_name: str, namespace: str):
    run_script(SCRIPT_PATH_GIT, [repo_name, namespace])

@router.post("/api/infra")
async def handle_request(payload: Payload):
    namespace = f"{payload.user}-{payload.project_name}"
    app_name = payload.project_name
    repo_name = payload.repo_name

    if payload.action == "test":
        try:
            print("Starting initial setup script...")
            initial_setup(namespace, app_name, repo_name)
            print("Starting git commands script...")
            git_commands(repo_name, namespace)
            return {"status": "Deployment started", "data": payload.dict()}
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

    elif payload.action == "deploy":
        try:
            print("Deploying app...")
            run_deploy(repo_name, namespace)
            url = subprocess.check_output(["minikube", "service", f"{app_name}-service", "--url"], encoding="utf-8").strip()
            return {"message": "App deployed", "url": url}
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))
    
    raise HTTPException(status_code=400, detail="Invalid action")

# Include router in the app
app.include_router(router)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=3001)
