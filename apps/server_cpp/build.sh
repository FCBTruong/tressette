cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake
cmake --build build --config Debug

# Run the server
.\build\Debug\tressette_server.exe

# Run the client test
.\build\Debug\test_client.exe


# Build release server
docker build --no-cache -t tressette_server .
docker run --rm -p 8080:8080 tressette_server



# Linux build
wsl --install -d Ubuntu

sudo apt update
sudo apt install -y build-essential cmake libboost-dev nlohmann-json3-dev libprotobuf-dev protobuf-compiler

mkdir -p ~/workspace


rsync -av --delete \
  --exclude '.git' \
  --exclude '.vs' \
  --exclude 'build' \
  --exclude 'dist' \
  --exclude 'cmake-build-*' \
  /mnt/c/Workspace/GameStudio/Tressette/apps/server_cpp/ \
  ~/workspace/server_cpp/

cd ~/workspace/server_cpp

cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --target tressette_server -j"$(nproc)"

# test on linux
cd ~/workspace/server_cpp/build
./tressette_server

# copy the binary to dist folder
cp /root/workspace/server_cpp/build/tressette_server /mnt/c/Workspace/GameStudio/Tressette/apps/server_cpp/build/linux/

# run aws
scp -i "C:\Workspace\GameStudio\Tressette\apps\server_cpp\secrets\key.pem" "C:\Workspace\GameStudio\Tressette\apps\server_cpp\build\linux\tressette_server" ubuntu@35.152.52.25:/home/ubuntu/tressette/

scp -i "C:\Workspace\GameStudio\Tressette\apps\server_cpp\secrets\key.pem" -r "C:\Workspace\GameStudio\Tressette\apps\server_cpp\config" ubuntu@35.152.52.25:/home/ubuntu/tressette/
ssh -i "C:\Workspace\GameStudio\Tressette\apps\server_cpp\secrets\key.pem" ubuntu@35.152.52.25


# create systemmd
sudo tee /etc/systemd/system/tressette.service >/dev/null <<'EOF'
[Unit]
Description=Tressette C++ Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/tressette
ExecStart=/home/ubuntu/tressette/tressette_server
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable tressette
sudo systemctl start tressette

# check status
sudo systemctl status tressette

## NGINX
sudo apt update
sudo apt install -y nginx

sudo tee /etc/nginx/sites-available/tressette-live-cpp >/dev/null <<'EOF'
server {
    listen 80;
    server_name tressette-live-cpp.clareentertainment.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_read_timeout 86400;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/tressette-live-cpp /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx