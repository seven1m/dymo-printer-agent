TODO: write intro

## Setup

1.  Build the Check-ins Electron app on your Mac:

    ```
    cd check-ins-desktop
    yarn
    node_modules/.bin/build --linux tar.xz --armv7l
    ```

1.  Copy the Check-ins Electron app to the Raspberry Pi and extract it:

    ```
    scp dist/planning-center-check-ins-*-armv7l.tar.xz pi@raspberry.local:~/
    ssh pi@raspberry.local "tar xJf planning-center-check-ins-*-armv7l.tar.xz"
    ```

1.  On the Raspberry Pi, run the Electron app at:

    ```
    /home/pi/planning-center-check-ins-1.4.1-armv7l/planning-center-check-ins
    ```

    ...and create a new station.

1.  Install some prerequisites for the printer agent:

    ```
    sudo apt update
    sudo apt install build-essential openssl ruby-dev libssl-dev cups printer-driver-dymo
    sudo gpasswd -a pi lpadmin
    ```

1.  Add the printer via the Cups admin page:

    http://localhost:631/

1.  Copy this repo to the Raspberry Pi.

1.  Bundle:

    ```
    sudo gem install bundler
    cd check-ins-rpi-printer
    bundle
    ```

1.  Start the printer agent:

    ```
    cd check-ins-rpi-printer
    ruby agent.rb
    ```
