_print label XML to a Dymo printer on any platform_

## What?

The Dymo tray application runs on Windows and Mac, but not Linux. I wanted to be able
to use the JavaScript SDK to print from a browser on Linux, so I wrote this Ruby program
to act like the Dymo app.

This app sets up a small web server on port 41951 and accepts POST requests with XML.
The XML is interpretted, albeit not perfectly, and rendered to PDF, which is then
sent directly to the Dymo print driver.

**You would not normally be writing the XML yourself. Instead, you should build your label
in the Dymo software and interface with the API using the
[Dymo SDK JavaScript Library](http://developers.dymo.com/2018/05/29/updated-js-sdk-and-dls/).**

### What Works

* Basic text and auto-shrinking text
* Text box solid background colors
* Horizontal lines
* "Verticalized" text

### What Doesn't Work, Yet (Pull Requests Welcome!)

* Barcodes
* Rotated text
* Other shapes
* Alpha transparency on background colors
* Multiple font sizes/styles in the same text box (probably not possible)
* Probably other stuff

### What's Quirky

Some text is not placed exactly the same with this app as Dymo would do it. Dymo and Prawn have very subtle
differences in how they render text. Some of those differences have been accounted for, but not all.

If your labels rely on precise placement/alignment of different objects, this solution may not work well for you.

Below are some samples:

* [Printed via the Dymo app](https://github.com/seven1m/dymo-printer-agent/blob/master/samples/dymo.png)
* [Printed via this Ruby app](https://github.com/seven1m/dymo-printer-agent/blob/master/samples/us.png)
* [Both images combined](https://github.com/seven1m/dymo-printer-agent/blob/master/samples/overlay.png)

## Setup

_These instructions should work on Debian and Ubuntu._

1.  Install some prerequisites:

    ```
    sudo apt update
    sudo apt install build-essential openssl ruby-dev libssl-dev cups printer-driver-dymo ttf-mscorefonts-installer
    ```

1.  Add the Tahoma font, which seems to be Dymo's default:

    ```
    cd /tmp
    wget https://sourceforge.net/projects/corefonts/files/OldFiles/IELPKTH.CAB
    cabextract -F 'tahoma.ttf' IELPKTH.CAB
    sudo mv tahoma.ttf /usr/share/fonts/truetype/msttcorefonts/Tahoma.ttf
    ```

1.  Allow your user account to manage printers with cups:

    ```
    sudo gpasswd -a USERNAME lpadmin
    ```

    Replace `USERNAME` above with your user, e.g. `pi` if running on Raspbian.

1.  Add the printer via the Cups admin page:

    http://localhost:631/

1.  Bundle:

    ```
    sudo gem install bundler
    cd
    git clone https://github.com/seven1m/dymo-printer-agent.git
    cd dymo-printer-agent
    bundle
    ```

1.  Generate a self-signed certificate:

    ```
    openssl req -nodes -new -x509 -keyout ca.key -out ca.crt -subj /CN=localhost -days 3650
    ```

1.  Start the printer agent:

    ```
    cd dymo-printer-agent
    ruby agent.rb
    ```

1.  There is currently a bug in the Dymo printer driver that causes long delays in between printing each label.
    In another terminal, start the `dymo_speed.rb` script to work around this issue:

    ```
    cd dymo-printer-agent
    ruby dymo_speed.rb
    ```

### Running on a Raspberry Pi

My specific use-case for this script was to run it on a Raspberry Pi running Raspbian. I wanted the script
to auto-start upon boot of the Raspberry Pi. The following commands will set that up:

```
echo '@/home/pi/dymo-printer-agent/start_in_lxterminal.sh' >> ~/.config/lxsession/LXDE-pi/autostart
echo '@ruby /home/pi/dymo-printer-agent/dymo_speed.rb' >> ~/.config/lxsession/LXDE-pi/autostart
```

## License

Copyright Tim Morgan

Licensed under the 2-clause BSD license (see the LICENSE file in this repo)
