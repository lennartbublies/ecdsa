# fhw-ecdsa

Zur Problemlösung in einem Gesamtsystem stehen vielseitige Vorgehensweisen zur
Verfügung. Durch die Softwareentwicklung lässt sich eine Lösung entwerfen, die
stark auf das Problemfeld zugeschnitten ist, sich aber dennoch flexibel
gestalten lässt. Der Aufwand für Anpassungen ist gering und neue Anforderungen
lassen sich simpel umsetzen.

Bei leistungskritischen Problemfeldern ist jedoch der Einsatz einer
Hardwarelösung zu betrachten. Neben dem Einsatz von spezialisierten
Prozessoren, die bestimmte mathematische Operationen beschleunigen, können mit
Hilfe von ASICs maßgeschneiderte Lösungen erstellt werden, die einen großen
Leistungsvorteil gegenüber einer allgemeinen Softwarelösung ermöglichen.

Im Themengebiet Reconfigurable Computing wird eine Zwischenlösung gesucht, die
die Leistungsvorteile aus der Hardwareentwicklung mit sich bringt, aber dennoch
die Flexibilität einer Softwarelösung bereitstellt (Compton 2002).

In dieser Arbeit wird das Themengebiet an Hand eines Beispiels aus der
Verschlüsselungstechnik betrachtet. Es wird für den ECDSA Algorithmus eine
Softwarelösung vorgestellt, die sich mit einfachen Mitteln in Hardware umsetzen
lässt. Die Einschränkung auf Koblitzkurven begünstigt dabei die Umsetzung. Der
Focus dieser Arbeit liegt bei der Softwarelösung, es werden jedoch Algorithmen
und Verfahren vorgestellt, die eine Optimierung auf der Hardwareebene
ermöglichen.

Die Abkürzung ECDSA steht für „Elliptic Curve Digital Signature Algorithm“. Es
handelt sich dabei um ein Verfahren zur digitalen Signatur von Nachrichten, bei
dem der Absender der Nachricht zweifelsfrei bestätigt werden kann.

Das Verfahren basiert auf den mathematischen Eigenschaften von elliptischen
Kurven und gewinnt gegenüber klassischen Verfahren wie RSA und DSA immer mehr
an Popularität. Die Schlüssellänge ist bei gleichen Sicherheitsanforderungen
deutlich geringer als bei RSA und DSA.

Nachfolgend wird zunächst in die Theorie von elliptischen Kurven eingeführt und
die mathematischen Grundlagen betrachtet. Es wird zudem in die Algorithmen
eingeführt, die für die Berechnung notwendig sind. Im Anschluß wird die im
Rahmen dieser Arbeit entwickelte Softwarelösung vorgestellt und ein Ausblick
darauf gegeben, welche weitere Arbeit folgen kann.

## Verifikation der Funktionsweise

Durch aufruf der Funktionstests kann das Programm überprüft werden. Folgender
Befehl startet die Tests:

    $ make test

Optional können auch die erweiterten Tests durchlaufen werden, die mehr
Verarbeitungszeit in Anspruch nehmen.

    $ make test TEST_VERBOSE=1
