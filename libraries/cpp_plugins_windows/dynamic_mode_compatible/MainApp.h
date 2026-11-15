class MagnifierWindow;

class MainApp
{
public:
    MainApp();
    ~MainApp();

    void initialize();
    void showMagnifier();

private:
    MagnifierWindow* _magnifierWindow;
};