#include <iostream>

// main loop
int main() {
    cout << "Calculator (type quit to exit)\n";

    while (cin) {
        try {
            cout << "> ";
            Token t = ts.get();
            if (t.kind == quit) break;

            ts.putback(t);
            double val = expression();

            cout << "= " << val << endl;
        }
        catch (exception& e) {
            cout << e.what() << endl;
            ts.ignore(';');
        }
    }
}