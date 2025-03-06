# Backend Deployment Orchestration

## Overview
This architecture automates backend deployments using a self-hosted Git server, an orchestration application, and a Kubernetes-based backend environment.

## Components

### 1. Self-Hosted Git Server
- Developers push code changes to this Git server.
- The server notifies the **Orchestration App** via **WebSockets** about new commits.

### 2. Orchestration App
- Listens for new code notifications from the Git server.
- Pulls the latest code and initiates tests.
- Sends test completion events back to the **Backend App**.
- If tests pass, triggers deployment to production.
- Can create a new backend namespace in Kubernetes when needed.

### 3. Backend App
- Receives test completion events from the **Orchestration App**.
- Can take further actions based on test results.

### 4. Kubernetes Environment (K8s Namespaces)
- Each backend runs inside its own **Kubernetes namespace** on a **VPS node**.
- The orchestration process includes:
  - Pulling the latest code.
  - Running tests on the code.
  - Deploying to production when tests pass.
  - Creating new backend environments when required.

---

## Deployment Flow

### 1. Push Code Changes
- Developers push new code to the **Self-Hosted Git Server**.

### 2. Code Update Notification
- The Git server sends a message to the **Orchestration App** via **WebSockets**.

### 3. Orchestration App Actions
- Pulls the latest code from the Git server.
- Triggers a new pull request to the Kubernetes namespace.
- Tests the running code.

### 4. Test Results
- The **Orchestration App** sends test results back to the **Backend App**.

### 5. Deployment to Production
- If tests pass, the **Orchestration App** deploys the backend to production.

### 6. Creating New Backend Instances
- If required, a new Kubernetes namespace is created for additional backend instances.
## Key Technologies

- **Git Server** – Self-hosted version control system.  
- **WebSockets** – Real-time communication between the Git server and the orchestration app.  
- **FastAPI / Express.js** – Potential backend frameworks for the Orchestration App.  
- **Kubernetes** – Orchestrates backend deployments.  
- **VPS Node** – Hosts Kubernetes namespaces.  
sequenceDiagram
    Client->>Server: Connect via WS
    Client->>Server: Send commit+test command
    Server->>K8s: Create namespace
    Server->>K8s: Deploy test pod
    K8s->>TestPod: Clone repo
    K8s->>TestPod: Checkout commit
    K8s->>TestPod: Run tests
    TestPod->>Server: JSON results
    Server->>Client: Return results
# Setup Instructions

## 1️⃣ Prerequisites
Before setting up the system, ensure you have:

- **Docker & Docker Compose** installed  
- **Kubernetes (K8s) cluster** set up (e.g., Minikube, k3s, or a managed K8s service)  
- **Self-hosted Git server** (e.g., Gitea, GitLab, or a bare Git repo)  
- **FastAPI / Express.js** for the orchestration app 
- **Kubectl** configured and working
- **Python 3.9+**

---

## 2️⃣ Setting Up the Git Server
If using **Gitea**, run the following command:

```bash
docker run -d --name gitea -p 3000:3000 -p 22:22 gitea/gitea
```
## 3️⃣ Deploying the Orchestration App

### Clone the Repository:
```bash
git clone https://your-git-server.com/your-repo.git
cd your-repo
```
#### Install Dependencies (Python FastAPI Example):
```bash
pip install -r requirements.txt
```
#### Start the Orchestration Service:
```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```
## 📋 Test Flow Breakdown

1. **Client connects via WebSocket**  
2. **Server creates an isolated Kubernetes (K8s) namespace**  
3. **Test pod deploys with a project-specific template**  
4. **Repository is cloned/updated inside the test pod**  
5. **Target commit is checked out**  
6. **Custom test command executes**  
