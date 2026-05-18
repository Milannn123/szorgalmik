import sys
import math

class Csomopont:
    def __init__(self, betu='/'):
        self.betu = betu
        self.balNulla = None
        self.jobbEgy = None

class LZWBinFa:
    def __init__(self):
        self.gyoker = Csomopont('/')
        self.fa = self.gyoker
        self.melyseg = 0
        self.maxMelyseg = 0
        self.atlagosszeg = 0
        self.atlagdb = 0
        self.szorasosszeg = 0.0
        self.atlag = 0.0
        self.szoras = 0.0

    def __lshift__(self, b):
        if b == '0':
            if not self.fa.balNulla:
                self.fa.balNulla = Csomopont('0')
                self.fa = self.gyoker
            else:
                self.fa = self.fa.balNulla
        else:
            if not self.fa.jobbEgy:
                self.fa.jobbEgy = Csomopont('1')
                self.fa = self.gyoker
            else:
                self.fa = self.fa.jobbEgy
        return self

    def kiir(self, f_out):
        self.melyseg = 0
        self._kiir(self.gyoker, f_out)

    def _kiir(self, elem, f_out):
        if elem is not None:
            self.melyseg += 1
            self._kiir(self.fa.jobbEgy if elem == self.fa else elem.jobbEgy, f_out)
            f_out.write("---" * self.melyseg + f"{elem.betu}({self.melyseg - 1})\n")
            self._kiir(self.fa.balNulla if elem == self.fa else elem.balNulla, f_out)
            self.melyseg -= 1

    def getMelyseg(self):
        self.melyseg = 0
        self.maxMelyseg = 0
        self._rmelyseg(self.gyoker)
        return self.maxMelyseg - 1

    def _rmelyseg(self, elem):
        if elem is not None:
            self.melyseg += 1
            if self.melyseg > self.maxMelyseg:
                self.maxMelyseg = self.melyseg
            self._rmelyseg(elem.jobbEgy)
            self._rmelyseg(elem.balNulla)
            self.melyseg -= 1

    def getAtlag(self):
        self.melyseg = 0
        self.atlagosszeg = 0
        self.atlagdb = 0
        self._ratlag(self.gyoker)
        self.atlag = self.atlagosszeg / self.atlagdb if self.atlagdb > 0 else 0
        return self.atlag

    def _ratlag(self, elem):
        if elem is not None:
            self.melyseg += 1
            self._ratlag(elem.jobbEgy)
            self._ratlag(elem.balNulla)
            self.melyseg -= 1
            if elem.jobbEgy is None and elem.balNulla is None:
                self.atlagdb += 1
                self.atlagosszeg += self.melyseg

    def getSzoras(self):
        self.atlag = self.getAtlag()
        self.szorasosszeg = 0.0
        self.melyseg = 0
        self.atlagdb = 0
        self._rszoras(self.gyoker)
        if self.atlagdb - 1 > 0:
            self.szoras = math.sqrt(self.szorasosszeg / (self.atlagdb - 1))
        else:
            self.szoras = math.sqrt(self.szorasosszeg)
        return self.szoras

    def _rszoras(self, elem):
        if elem is not None:
            self.melyseg += 1
            self._rszoras(elem.jobbEgy)
            self._rszoras(elem.balNulla)
            self.melyseg -= 1
            if elem.jobbEgy is None and elem.balNulla is None:
                self.atlagdb += 1
                self.szorasosszeg += (self.melyseg - self.atlag) ** 2

def main():
    if len(sys.argv) != 4 or sys.argv[2] != '-o':
        print("Usage: python3 lzwtree.py in_file -o out_file")
        sys.exit(-1)

    in_file = sys.argv[1]
    out_file = sys.argv[3]
    binFa = LZWBinFa()

    try:
        with open(in_file, "rb") as f_in:
            while True:
                b = f_in.read(1)
                if not b or b[0] == 0x0a:
                    break

            kommentben = False
            while True:
                b_bytes = f_in.read(1)
                if not b_bytes:
                    break
                
                b = b_bytes[0]
                
                if b == 0x3e: # '>' karakter
                    kommentben = True
                    continue
                if b == 0x0a: # újsor
                    kommentben = False
                    continue
                if kommentben:
                    continue
                if b == 0x4e: # 'N' betű
                    continue
                
                # Biteltolásos varázslat
                for _ in range(8):
                    if b & 0x80:
                        binFa << '1'
                    else:
                        binFa << '0'
                    b = (b << 1) & 0xFF

        with open(out_file, "w") as f_out:
            binFa.kiir(f_out)
            f_out.write(f"depth = {binFa.getMelyseg()}\n")
            f_out.write(f"mean = {binFa.getAtlag()}\n")
            f_out.write(f"var = {binFa.getSzoras()}\n")

    except FileNotFoundError:
        print(f"{in_file} nem letezik...")
        sys.exit(-3)

if __name__ == "__main__":
    main()
