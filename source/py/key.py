import keyboard

def on_key_press(event):
    if event.name == 'space':
        print("Space key pressed")

# 监听按键事件
keyboard.on_press(on_key_press)

# 运行程序，直到按下 'q' 键退出
keyboard.wait('q')

