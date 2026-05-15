import tkinter as tk


def show_overlay(message="What did you come here for?"):

    root = tk.Tk()

    root.title("Intentionality Check")

    root.geometry("400x250")

    root.configure(bg="#111111")

    label = tk.Label(
        root,
        text=message,
        font=("Helvetica", 18),
        fg="white",
        bg="#111111",
        wraplength=340,
        justify="center"
    )

    label.pack(pady=30)

    buttons = [
        "Learn",
        "Search",
        "Relax",
        "Message Someone"
    ]

    for text in buttons:

        button = tk.Button(
            root,
            text=text,
            width=20,
            height=2
        )

        button.pack(pady=5)

    root.mainloop()

if __name__ == "__main__":
    show_overlay()
