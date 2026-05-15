import tkinter as tk

def countdown(seconds, label, root):

    if seconds >= 0:

        label.config(
            text=f"Take one conscious breath.\n\nOpening in {seconds}..."
        )

        root.after(
            1000,
            countdown,
            seconds - 1,
            label,
            root
        )

    else:
        root.destroy()

def show_delay_overlay():

    root = tk.Tk()

    root.title("Intentional Pause")

    root.geometry("420x220")

    root.configure(bg="#111111")

    label = tk.Label(
        root,
        text="",
        font=("Helvetica", 18),
        fg="white",
        bg="#111111",
        justify="center"
    )

    label.pack(expand=True)

    countdown(
        3,
        label,
        root
    )

    root.mainloop()

if __name__ == "__main__":

    show_delay_overlay()