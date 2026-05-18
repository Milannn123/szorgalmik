package main

import (
	"bufio"
	"fmt"
	"io"
	"math"
	"os"
	"strings"
)

type Csomopont struct {
	betu     byte
	balNulla *Csomopont
	jobbEgy  *Csomopont
}


func ujCsomopont(b byte) *Csomopont {
	return &Csomopont{
		betu:     b,
		balNulla: nil,
		jobbEgy:  nil,
	}
}


type LZWBinFa struct {
	gyoker       *Csomopont
	fa           *Csomopont 
	melyseg      int
	maxMelyseg   int
	atlagosszeg  int
	atlagdb      int
	szorasosszeg float64
	atlag        float64
	szoras       float64
}


func ujLZWBinFa() *LZWBinFa {
	gy := ujCsomopont('/')
	return &LZWBinFa{
		gyoker: gy,
		fa:     gy, 
	}
}


func (bf *LZWBinFa) Push(b byte) {
	if b == '0' {
		if bf.fa.balNulla == nil { 
			bf.fa.balNulla = ujCsomopont('0') 
			bf.fa = bf.gyoker              
		} else {
			bf.fa = bf.fa.balNulla 
		}
	} else {
		if bf.fa.jobbEgy == nil {
			bf.fa.jobbEgy = ujCsomopont('1')
			bf.fa = bf.gyoker
		} else {
			bf.fa = bf.fa.jobbEgy
		}
	}
}


func (bf *LZWBinFa) Kiir(file *os.File) {
	bf.melyseg = 0
	bf.rkiir(bf.gyoker, file)
}

func (bf *LZWBinFa) rkiir(elem *Csomopont, file *os.File) {
	if elem != nil {
		bf.melyseg++
		bf.rkiir(elem.jobbEgy, file)
		

		indent := strings.Repeat("---", bf.melyseg)
		fmt.Fprintf(file, "%s%c(%d)\n", indent, elem.betu, bf.melyseg-1)
		
		bf.rkiir(elem.balNulla, file)
		bf.melyseg--
	}
}

func (bf *LZWBinFa) GetMelyseg() int {
	bf.melyseg = 0
	bf.maxMelyseg = 0
	bf.rmelyseg(bf.gyoker)
	return bf.maxMelyseg - 1
}

func (bf *LZWBinFa) rmelyseg(elem *Csomopont) {
	if elem != nil {
		bf.melyseg++
		if bf.melyseg > bf.maxMelyseg {
			bf.maxMelyseg = bf.melyseg
		}
		bf.rmelyseg(elem.jobbEgy)
		bf.rmelyseg(elem.balNulla)
		bf.melyseg--
	}
}

func (bf *LZWBinFa) GetAtlag() float64 {
	bf.melyseg = 0
	bf.atlagosszeg = 0
	bf.atlagdb = 0
	bf.ratlag(bf.gyoker)
	
	if bf.atlagdb > 0 {
		bf.atlag = float64(bf.atlagosszeg) / float64(bf.atlagdb)
	}
	return bf.atlag
}

func (bf *LZWBinFa) ratlag(elem *Csomopont) {
	if elem != nil {
		bf.melyseg++
		bf.ratlag(elem.jobbEgy)
		bf.ratlag(elem.balNulla)
		bf.melyseg--
		if elem.jobbEgy == nil && elem.balNulla == nil {
			bf.atlagdb++
			bf.atlagosszeg += bf.melyseg
		}
	}
}

func (bf *LZWBinFa) GetSzoras() float64 {
	bf.atlag = bf.GetAtlag()
	bf.szorasosszeg = 0.0
	bf.melyseg = 0
	bf.atlagdb = 0
	bf.rszoras(bf.gyoker)

	if bf.atlagdb-1 > 0 {
		bf.szoras = math.Sqrt(bf.szorasosszeg / float64(bf.atlagdb-1))
	} else {
		bf.szoras = math.Sqrt(bf.szorasosszeg)
	}
	return bf.szoras
}

func (bf *LZWBinFa) rszoras(elem *Csomopont) {
	if elem != nil {
		bf.melyseg++
		bf.rszoras(elem.jobbEgy)
		bf.rszoras(elem.balNulla)
		bf.melyseg--
		if elem.jobbEgy == nil && elem.balNulla == nil {
			bf.atlagdb++
			diff := float64(bf.melyseg) - bf.atlag
			bf.szorasosszeg += diff * diff
		}
	}
}


func main() {
	if len(os.Args) != 4 || os.Args[2] != "-o" {
		fmt.Println("Usage: go run lzwtree.go in_file -o out_file")
		os.Exit(-1)
	}

	inFile := os.Args[1]
	outFile := os.Args[3]

	beFile, err := os.Open(inFile)
	if err != nil {
		fmt.Println(inFile, "nem letezik...")
		os.Exit(-3)
	}
	defer beFile.Close()

	kiFile, err := os.Create(outFile)
	if err != nil {
		fmt.Println("Hiba a kimeneti fajl letrehozasakor.")
		os.Exit(-4)
	}
	defer kiFile.Close()

	binFa := ujLZWBinFa()
	reader := bufio.NewReader(beFile)


	for {
		b, err := reader.ReadByte()
		if err != nil || b == 0x0a {
			break
		}
	}

	kommentben := false


	for {
		b, err := reader.ReadByte()
		if err != nil {
			if err == io.EOF {
				break
			}
			break
		}

		if b == 0x3e { 
			kommentben = true
			continue
		}
		if b == 0x0a { 
			kommentben = false
			continue
		}
		if kommentben {
			continue
		}
		if b == 0x4e { 
			continue
		}

		for i := 0; i < 8; i++ {
			if (b & 0x80) != 0 {
				binFa.Push('1')
			} else {
				binFa.Push('0')
			}
			b <<= 1
		}
	}

	binFa.Kiir(kiFile)
	fmt.Fprintf(kiFile, "depth = %d\n", binFa.GetMelyseg())
	fmt.Fprintf(kiFile, "mean = %f\n", binFa.GetAtlag())
	fmt.Fprintf(kiFile, "var = %f\n", binFa.GetSzoras())
}
