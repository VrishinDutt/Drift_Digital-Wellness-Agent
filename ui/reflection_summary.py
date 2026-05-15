import tkinter as tk

def generate_summary():

    return (
        "Your passive usage patterns increased "
        "after periods of rapid app switching.\n\n"
        "Short intentional pauses may help restore focus."
    )

def show_summary():

    root = tk.Tk()

    root.title("Behavior Reflection")

    root.geometry("520x320")

    root.configure(bg="#111111")

    text = tk.Label(
        root,
        text=generate_summary(),
        font=("Helvetica", 18),
        fg="white",
        bg="#111111",
        wraplength=450,
        justify="left"
    )

    text.pack(
        expand=True,
        padx=30,
        pady=30
    )

    button = tk.Button(
        root,
        text="Close",
        width=20,
        height=2,
        command=root.destroy
    )

    button.pack(pady=20)

    root.mainloop()

if __name__ == "__main__":

    show_summary()