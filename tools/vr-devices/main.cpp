/*
 * main.cpp -- list the devices a running Monado service exposes.
 *
 * Talks to monado-service over its IPC socket through libmonado, so it shows
 * what OpenXR clients see: names, serials, which DoF each device supports, and
 * which device fills each role.
 *
 * Exit codes: 0 = connected and listed, 1 = no service running.
 */
#include <monado/monado.h>

#include <array>
#include <cstdint>
#include <optional>
#include <print>
#include <string>
#include <string_view>
#include <utility>

namespace {

using DeviceIndex = std::uint32_t;

/* Battery state of a device that has one. */
struct Battery {
  float charge = 0.0f;  // 0..1
  bool charging = false;
};

/* Roles the service assigns devices to. */
enum class Role : std::uint8_t {
  Head,
  Left,
  Right,
  Gamepad,
};

constexpr std::array kRoles{Role::Head, Role::Left, Role::Right, Role::Gamepad};

constexpr std::string_view to_string(Role role) {
  switch (role) {
    case Role::Head:
      return "head";
    case Role::Left:
      return "left";
    case Role::Right:
      return "right";
    case Role::Gamepad:
      return "gamepad";
  }
  std::unreachable();
}

/* Connection to a running monado service; owns the IPC handle. */
class Client {
 public:
  static std::optional<Client> connect() {
    Client client;
    if (mnd_root_create(&client.root_) != MND_SUCCESS) {
      return std::nullopt;
    }
    return client;
  }

  Client(const Client&) = delete;
  Client& operator=(const Client&) = delete;

  Client(Client&& other) noexcept : root_{std::exchange(other.root_, nullptr)} {}

  Client& operator=(Client&& other) noexcept {
    if (this != &other) {
      destroy();
      root_ = std::exchange(other.root_, nullptr);
    }
    return *this;
  }

  ~Client() { destroy(); }

  std::optional<DeviceIndex> device_count() const {
    DeviceIndex count = 0;
    if (mnd_root_get_device_count(root_, &count) != MND_SUCCESS) {
      return std::nullopt;
    }
    return count;
  }

  std::optional<std::string_view> string_property(DeviceIndex index, mnd_property_t prop) const {
    const char* value = nullptr;
    if (mnd_root_get_device_info_string(root_, index, prop, &value) != MND_SUCCESS || value == nullptr) {
      return std::nullopt;
    }
    return std::string_view{value};
  }

  std::optional<bool> bool_property(DeviceIndex index, mnd_property_t prop) const {
    bool value = false;
    if (mnd_root_get_device_info_bool(root_, index, prop, &value) != MND_SUCCESS) {
      return std::nullopt;
    }
    return value;
  }

  std::optional<Battery> battery(DeviceIndex index) const {
    Battery battery;
    bool present = false;
    if (mnd_root_get_device_battery_status(root_, index, &present, &battery.charging, &battery.charge) != MND_SUCCESS ||
        !present) {
      return std::nullopt;
    }
    return battery;
  }

  std::optional<DeviceIndex> device_for(Role role) const {
    const std::string name{to_string(role)};  // the API takes a null-terminated name
    std::int32_t index = -1;
    if (mnd_root_get_device_from_role(root_, name.c_str(), &index) != MND_SUCCESS || index < 0) {
      return std::nullopt;
    }
    return static_cast<DeviceIndex>(index);
  }

 private:
  Client() = default;

  void destroy() {
    if (root_ != nullptr) {
      mnd_root_destroy(&root_);
      root_ = nullptr;
    }
  }

  mnd_root_t* root_ = nullptr;
};

/* Non-owning handle to one device of a Client. */
class Device {
 public:
  Device(const Client& client, DeviceIndex index) : client_{client}, index_{index} {}

  std::optional<std::string_view> name() const { return client_.string_property(index_, MND_PROPERTY_NAME_STRING); }

  std::optional<std::string_view> serial() const { return client_.string_property(index_, MND_PROPERTY_SERIAL_STRING); }

  std::optional<bool> supports_position() const {
    return client_.bool_property(index_, MND_PROPERTY_SUPPORTS_POSITION_BOOL);
  }

  std::optional<bool> supports_orientation() const {
    return client_.bool_property(index_, MND_PROPERTY_SUPPORTS_ORIENTATION_BOOL);
  }

  std::optional<Battery> battery() const { return client_.battery(index_); }

  void print() const {
    std::print("  [{}] ", index_);
    if (const auto value = name()) {
      std::print("name={} ", *value);
    }
    if (const auto value = serial()) {
      std::print("serial={} ", *value);
    }
    print_flag("position", supports_position());
    print_flag("orientation", supports_orientation());
    if (const auto value = battery()) {
      std::print("battery={:.0f}%{} ", value->charge * 100.0f, value->charging ? "(charging)" : "");
    }
    std::println();
  }

 private:
  static void print_flag(std::string_view label, std::optional<bool> value) {
    if (value) {
      std::print("{}={} ", label, *value ? "yes" : "no");
    }
  }

  const Client& client_;
  DeviceIndex index_;
};

void print_devices(const Client& client, DeviceIndex count) {
  for (DeviceIndex index = 0; index < count; ++index) {
    Device{client, index}.print();
  }
}

void print_roles(const Client& client) {
  for (const Role role : kRoles) {
    const auto index = client.device_for(role);
    if (!index) {
      continue;
    }
    const Device device{client, *index};
    std::println("  role {:8} -> [{}] {}", to_string(role), *index, device.name().value_or("(unnamed)"));
  }
}

}  // namespace

int main() {
  const auto client = Client::connect();
  if (!client) {
    std::println(stderr, "could not connect to a running monado service; start monado-service");
    return 1;
  }

  const auto count = client->device_count();
  if (!count) {
    std::println(stderr, "could not read the device list");
    return 1;
  }

  std::println("devices: {}", *count);
  print_devices(*client, *count);
  print_roles(*client);

  return 0;
}
