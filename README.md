_a hacky solution to printing labels to a Dymo printer using a Raspberry Pi_

## What?

The Check-ins app relies on the Dymo tray app widget thing to convert label XML
into a PDF for the printer. Since the Dymo app doesn't run on Linux, this small Ruby
app aims to replace it.

This app sets up a small web server on port 41951 and accepts POST requests with XML.
The XML is interpretted, albeit not perfectly, and rendered to PDF, which is then
sent directly to the Dymo print driver.

### What Works

* Basic text and auto-shrinking text
* Text box solid background colors
* Horizontal lines
* "Verticalized" text

### What Doesn't Work (Yet)

* Rotated text
* Multiple font sizes/styles in the same text box
* Other shapes
* Alpha transparency on background colors
* Probably other stuff

### What's Quirky

Some text is not placed exactly the same with this app as Dymo would do it. Dymo and Prawn have very subtle
differences in how they place text, space characters, and auto-fit text. Some of those differences have been
accounted for, but not all.

If your labels rely on precise placement/alignment of different objects, this solution may not work well for you.

Below are some samples:

* [Printed via the Dymo app](https://github.com/ministrycentered/check-ins-rpi-printer/blob/master/samples/dymo.png)
* [Printed via this Ruby app](https://github.com/ministrycentered/check-ins-rpi-printer/blob/master/samples/us.png)
* [Both images combined](https://github.com/ministrycentered/check-ins-rpi-printer/blob/master/samples/overlay.png)

## Setup

1.  Build the Check-ins Electron app on your Mac:

    ```
    cd check-ins-desktop
    yarn
    node_modules/.bin/build --linux tar.xz --armv7l
    ```

1.  Enable ssh on the Raspberry Pi and change the default password:

    ```
    sudo systemctl enable ssh
    sudo service ssh start
    passwd
    ```

    Change the password to something secure.

1.  Copy the Check-ins Electron app to the Raspberry Pi and extract it:

    ```
    scp dist/planning-center-check-ins-*-armv7l.tar.xz pi@raspberry.local:~/
    ssh pi@raspberry.local "tar xJf planning-center-check-ins-*-armv7l.tar.xz && mv planning-center-check-ins-*-armv7l planning-center-check-ins"
    ```

1.  On the Raspberry Pi, run the Electron app at:

    ```
    /home/pi/planning-center-check-ins/planning-center-check-ins
    ```

    ...and create a new station.

1.  Install some prerequisites for the printer agent:

    ```
    sudo apt update
    sudo apt install build-essential openssl ruby-dev libssl-dev cups printer-driver-dymo ttf-mscorefonts-installer
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

1.  Set the software to auto-start:

    ```
    echo '@/home/pi/check-ins-rpi-printer/start_station.sh' >> ~/.config/lxsession/LXDE-pi/autostart
    echo '@/home/pi/check-ins-rpi-printer/start_printer_agent.sh' >> ~/.config/lxsession/LXDE-pi/autostart
    echo '@ruby /home/pi/check-ins-rpi-printer/dymo_speed.rb' >> ~/.config/lxsession/LXDE-pi/autostart
    ```
