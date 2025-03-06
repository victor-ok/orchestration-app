from pydantic import BaseModel

class Payload(BaseModel):
    repo_name: str
    project_name: str
    user: str
    action: str
