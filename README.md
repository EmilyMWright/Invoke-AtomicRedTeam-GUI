## A GUI for the Invoke Atomic Red Team PowerShell Module

Atomic Red Team is a library of small, highly portable detection tests mapped to the MITRE ATT&CK Framework. This GUI provides a Windows Form to interact with the [Invoke Atomic Red Team PowerShell module](https://github,com/redcanaryco/invoke-atomicredteam). Users can run existing tests and create new tests.

### Usage

From a PowerShell prompt, use `IART_GUI.ps1` to start the GUI.

#### Running Tests

Tests are run by specifying the ATT&CK Technique number to which the test is mapped. 

- Type the technique number or use the **browse...** button to navigate to the folder of the technique number.
- Use the **Test** drop down to select a specific test (default 'All')
- Select an action from the drop down menu (for more details on the purpose of each action, peruse the [Invoke Atomic Red Team Wiki](https://github,com/redcanaryco/invoke-atomicredteam/wiki)).
- If you selected a specific test, you can edit the default inputs in the **Edit default inputs** data grid