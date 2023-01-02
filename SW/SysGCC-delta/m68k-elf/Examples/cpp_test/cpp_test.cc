#define USE_IOSTREAM

#ifdef USE_IOSTREAM
/* Test Driver for the Complex class (TestComplex.cpp) */
  #include <iostream>
  #include <iomanip>
#else
  #include <stdio.h>
#endif

#include "complex.h"
using namespace std;
 
int main() {
   Complex c1, c2(4, 5);
   c1.print();  // (0,0)
   c2.print();  // (4,5)
 
   c1.setValue(6, 7);
   c1.print();  // (6,7)
 
   c1.setReal(0);
   c1.setImag(8);
   c1.print();  // (0,8)
 
   #ifdef USE_IOSTREAM
     cout << boolalpha;  // print true/false instead of 0/1
     cout << "Is real? " << c1.isReal() << endl;           // false
     cout << "Is Imaginary? " << c1.isImaginary() << endl; // true
   #else
     printf("Is real? %u\r\n",c1.isReal());
     printf("Is Imaginary? %u\r\n", c1.isImaginary());
   #endif

   c1.addInto(c2).addInto(1, 1).print();  // (5,14)
   c1.print();  // (5,14)
 
   c1.addReturnNew(c2).print();   // (9,19)
   c1.print();  // (5,14) - no change in c1
   c1.addReturnNew(1, 1).print(); // (6,15)
   c1.print();  // (5,14) - no change in c1
}

/*#include <iostream>
#include <cstdint>
#include <array>
#include <stdint.h>
#include <stdio.h>

#define LAST    101

class squares {
    std::array<uint16_t, LAST> arr;
    public:
    squares(int num) {
        for (int i = 0; i < LAST; i++)
        {
            arr[i] = i * i;
        }
    }

    void printme() {
        for (auto const &value: arr)
            std::cout << value << ", "<< std::endl;
    }
    #if 0
    void printme() {
        for (auto const &value: arr)
            iprintf("%d\r\n, ", value);
    }
    #endif
};

int main()
{
    iprintf("Squares CPP Test\r\n");
    std::cout << "Hello cpp"<<std::endl;
    squares(10).printme();
}*/