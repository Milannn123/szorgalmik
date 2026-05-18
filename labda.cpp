#include <iostream>
#include <thread>
#include <chrono>
#include <cstdlib>

using namespace std;

const int WIDTH = 40;
const int HEIGHT = 15;

int main() {
    int x = WIDTH / 2;
    int y = HEIGHT / 2;
    int dx = 1;
    int dy = 1;

    while (true) {

        system("CLS");


        for (int row = 0; row < HEIGHT; row++) {
            for (int col = 0; col < WIDTH; col++) {
                if (row == y && col == x)
                    cout << "O";
                else
                    cout << ".";
            }
            cout << "\n";
        }


        x += dx;
        y += dy;

        // falakról való visszapattanás
        if (x <= 0 || x >= WIDTH - 1) dx = -dx;
        if (y <= 0 || y >= HEIGHT - 1) dy = -dy;

        this_thread::sleep_for(chrono::milliseconds(100));
    }


}
