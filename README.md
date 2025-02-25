## 🚀 Automated Deployment Script  

### 📌 Overview  

This document provides a Bash script for automated deployment of a GitHub repository to a web server. It ensures that all necessary packages are installed, sets up Nginx, fetches the latest commit from GitHub, and updates the deployment directory.  

### 🛠 How to Run and Execute  

#### 🔹 Running the Deployment Script  

1. Save the script as `deploy.sh`.  
2. Make the script executable:  
   ```bash
   chmod +x deploy.sh
   ```  
3. Run the script as root:  
   ```bash
   sudo ./deploy.sh
   ```  

👉 **What the script does:**  
- 📺 Installs required packages  
- 🔍 Checks if Nginx is running and restarts if necessary  
- 🛠 Sets up the environment and permissions  
- 🔄 Fetches the latest commit from the GitHub repository  
- 🚀 Deploys the latest changes  
- 🔄 Restarts Nginx to apply the updates  

#### 🔹 Running the Nginx Setup Script  

1. Save the Nginx setup script as `nginx_setup.sh`.  
2. Make the script executable:  
   ```bash
   chmod +x nginx_setup.sh
   ```  
3. Run the script as root:  
   ```bash
   sudo ./nginx_setup.sh
   ```  

👉 **What the script does:**  
- 🔄 Updates system packages  
- 🌍 Creates and configures an Nginx virtual host  
- ✅ Enables the configuration  
- ⚙️ Tests and reloads the Nginx configuration  

If successful, Nginx will be configured to serve the application on **port 8080**.  

### 🛠 Setting Up a Cron Job for `deploy.sh` with Logging  

To automate the deployment script execution at regular intervals, set up a cron job:  

1. Open the crontab editor:  
   ```bash
   sudo crontab -e
   ```  
2. Add the following line to schedule `deploy.sh` to run every minute and log output:  
   ```bash
   * * * * * /path/to/deploy.sh >> /var/log/deploy.log 2>&1
   ```  
3. Save and exit the crontab editor.  

👉 **What this cron job does:**  
- Runs `deploy.sh` every minute.  
- Redirects both stdout and stderr to `/var/log/deploy.log`.  
- Ensures logs are available for troubleshooting.

### 📌 Summary  

This deployment automation script ensures the web server runs smoothly with the latest updates from GitHub. It also configures **Nginx** to serve the application on **port 8080**. Additionally, a cron job is set up to execute `deploy.sh` every minute with logs stored in `/var/log/deploy.log`. 🚀