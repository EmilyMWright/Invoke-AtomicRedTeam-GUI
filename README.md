## A GUI for the Invoke Atomic Red Team PowerShell Module

Atomic Red Team is a library of small, highly portable detection tests mapped to the MITRE ATT&CK Framework. This GUI provides a Windows Form to interact with the [Invoke Atomic Red Team PowerShell module](https://github,com/redcanaryco/invoke-atomicredteam). Users can run existing tests and create new tests.

### Usage

From a PowerShell prompt, use `IEX (IWR "https://raw.githubusercontent.com/EmilyMWright/Invoke-AtomicRedTeam-GUI/master/IART_GUI.ps1" -UseBasicParsing); StartGUI` to start the GUI. If your AtomicRedTeam folder is not in the default location, append `-AtomicFolderPath "yourpath\AtomicRedTeam"` to the command.

#### Running Tests

Tests are run using the Invoke-AtomicRedTeam [Invoke-AtomicTest module](https://github.com/redcanaryco/invoke-atomicredteam/blob/master/Public/Invoke-AtomicTest.ps1) by specifying the ATT&CK Technique number to which the test is mapped. 

- On the home page, type the technique number or use the **Browse...** button to navigate to the folder of the technique number.
- Use the **Test** drop down to select a specific test (default 'All')
- Select an action from the drop down menu (for more details on the purpose of each action, peruse the [Invoke Atomic Red Team Wiki](https://github,com/redcanaryco/invoke-atomicredteam/wiki)).
- If you selected a specific test, you can edit the default input values in the **Edit default inputs** data grid

#### Creating Tests

Tests are created using the Invoke-AtomicRedTeam [New-Atomic module](https://github.com/redcanaryco/invoke-atomicredteam/blob/master/Public/New-Atomic.ps1). Each new test must be added to an ATT&CK Technique (either existing or new).

- From the home page, click **Create Test**. You will be directed to a new window to specify the test parameters.
- Fill in test parameters. If your test will be similar to an existing test, you can pre-fill the form with parameters from an existing test. Type the technique number or use the **Browse...** button to navigate to the folder of the technique number, then click **Load Test**. To reset all parameters, click **Clear**.
- Optionally, fill in input parameters and click **Add Input**. To modify an input, select it in the **Input List**, make your changes and click **Update Input**. To remove it altogether, click **Remove Input**.
- Optionally, fill in dependency parameters and click **Add Dependency**. To modify a dependency, select it in the **Dependency List**, make your changes and click **Update Dependency**. To remove it altogether, click **Remove Dependency**.
- Click **Create Test**. You will be directed to a new window to add the test to a technique.
- To create a new technique, fill in the attack technique parameters and click **Add test to new attack technique**. Alternatively, append the test to an exisitng technique. Type the technique number or use the **Browse...** button to navigate to the folder of the technique number, then click **Add test to existing attack technique**.

#### Test Parameters

The minimum parameters are test name, test description, supported platforms, and either executor type and executor command, or executor steps. 

