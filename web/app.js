const app = document.getElementById("app");
const vehicleList = document.getElementById("vehicle-list");
const closeButton = document.getElementById("close");
const cancelButton = document.getElementById("cancel");
const rentButton = document.getElementById("rent");
const title = document.getElementById("title");
const locationName = document.getElementById("location");
const selectedName = document.getElementById("selected-name");
const selectedModel = document.getElementById("selected-model");
const selectedPrice = document.getElementById("selected-price");

let selectedVehicle = null;

function resourceName() {
    return window.GetParentResourceName ? window.GetParentResourceName() : "venox-rental";
}

function postNui(event, data = {}) {
    return fetch(`https://${resourceName()}/${event}`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json; charset=UTF-8"
        },
        body: JSON.stringify(data)
    });
}

function money(value) {
    return `$${Number(value || 0).toLocaleString("en-US")}`;
}

function setSelected(vehicle, index) {
    selectedVehicle = { ...vehicle, index };

    document.querySelectorAll(".vehicle").forEach((item) => {
        item.classList.toggle("selected", Number(item.dataset.index) === index);
    });

    selectedName.textContent = vehicle.label || "Vehicle";
    selectedModel.textContent = vehicle.model || "standard rental";
    selectedPrice.textContent = money(vehicle.price);
    rentButton.disabled = false;
}

function renderVehicles(vehicles) {
    vehicleList.innerHTML = "";
    selectedVehicle = null;
    selectedName.textContent = "Choose a ride";
    selectedModel.textContent = "Pick a vehicle from the list.";
    selectedPrice.textContent = "$0";
    rentButton.disabled = true;

    vehicles.forEach((vehicle, index) => {
        const button = document.createElement("button");
        button.className = "vehicle";
        button.type = "button";
        button.dataset.index = String(index + 1);
        button.innerHTML = `
            <span>
                <span class="vehicle-name">${vehicle.label || vehicle.model}</span>
                <span class="vehicle-model">${vehicle.model || "rental"}</span>
            </span>
            <span class="vehicle-price">${money(vehicle.price)}</span>
        `;
        button.addEventListener("click", () => setSelected(vehicle, index + 1));
        vehicleList.appendChild(button);
    });

    if (vehicles.length > 0) {
        setSelected(vehicles[0], 1);
    }
}

function close() {
    app.classList.remove("open");
    app.setAttribute("aria-hidden", "true");
    postNui("close");
}

window.addEventListener("message", (event) => {
    const data = event.data || {};

    if (data.action === "open") {
        title.textContent = data.title || "Vehicle Rental";
        locationName.textContent = data.location || "Rental Point";
        renderVehicles(data.vehicles || []);
        app.classList.add("open");
        app.setAttribute("aria-hidden", "false");
    }

    if (data.action === "close") {
        app.classList.remove("open");
        app.setAttribute("aria-hidden", "true");
    }
});

closeButton.addEventListener("click", close);
cancelButton.addEventListener("click", close);

rentButton.addEventListener("click", () => {
    if (!selectedVehicle) {
        return;
    }

    postNui("rent", { vehicleIndex: selectedVehicle.index });
});

window.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
        close();
    }
});
