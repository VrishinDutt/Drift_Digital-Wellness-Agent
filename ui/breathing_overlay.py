import tkinter as tk

class BreathingOverlay:

    def __init__(self):

        self.root = tk.Tk()

        self.root.title("Breathing Reset")

        self.root.geometry("500x500")

        self.root.configure(bg="#111111")

        self.canvas = tk.Canvas(
            self.root,
            width=500,
            height=500,
            bg="#111111",
            highlightthickness=0
        )

        self.canvas.pack()

        self.label = tk.Label(
            self.root,
            text="Inhale",
            font=("Helvetica", 24),
            fg="white",
            bg="#111111"
        )

        self.label.place(
            relx=0.5,
            rely=0.1,
            anchor="center"
        )

        self.circle = self.canvas.create_oval(
            150,
            150,
            350,
            350,
            fill="#444444",
            outline=""
        )

        self.growing = True

        self.size = 200

        self.animate()

        self.root.mainloop()

    def animate(self):

        if self.growing:

            self.size += 2

            self.label.config(text="Inhale")

            if self.size >= 280:
                self.growing = False

        else:

            self.size -= 2

            self.label.config(text="Exhale")

            if self.size <= 180:
                self.growing = True

        center = 250

        radius = self.size / 2

        self.canvas.coords(
            self.circle,
            center - radius,
            center - radius,
            center + radius,
            center + radius
        )

        self.root.after(30, self.animate)

if __name__ == "__main__":

    BreathingOverlay()