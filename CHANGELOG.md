### v0.1.0
* **switch to the v1beta3 API** This includes a brand new protocol buffer file and an update to the underlying protocol buffer syntax version
* support lat/long geo point values
* refactor property and value implementations
* update to use the new DateTime structs in Elixir 1.3

#### Backwards Incompatible Changes
* DateTime property values must now be `%DateTime{}` structs. Previously, timestamps were passed in via a three-element tuple, which will now cause Diplomat to throw an exception when it tries to encode the value.
