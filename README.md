_a hacky solution to printing labels to a Dymo printer using a Raspberry Pi_

## What?

The Check-ins app relies on the Dymo tray app widget thing to convert label XML
into a PDF for the printer. Since the Dymo app doesn't run on Linux, this small Ruby
app aims to replace it.

This app sets up a small web server on port 41951 and accepts POST requests with XML.
The XML is interpretted, albeit not perfectly, and rendered to PDF, which is then
sent directly to the Dymo print driver.

### What Works

* Basic text
* text box solid background colors
* Horizontal lines
* "Verticalized" text

### What Doesn't Work (Yet)

* Auto-shrinking text
* Rotated text
* Other shapes
* Alpha transparency on background colors
* Probably other stuff

### What's Quirky

Some text is not placed exactly right. Dymo seems to have some inconsistent line spacing, kerning,
margins, and other alignment issues that haven't been fully imitated.

If your labels rely on precise, pixel-perfect placement/alignment of different objects,
this solution may not work well for you.

Below are some samples:

* [Printed via the Dymo app](https://github.com/ministrycentered/check-ins-rpi-printer/blob/master/samples/dymo.png)
* [Printed via this Ruby app](https://github.com/ministrycentered/check-ins-rpi-printer/blob/master/samples/us.png)

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
