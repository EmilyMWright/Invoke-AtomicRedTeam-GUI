## A GUI for the Invoke Atomic Red Team PowerShell Module

Atomic Red Team is a library of small, highly portable detection tests mapped to the MITRE ATT&CK Framework. This GUI provides a Windows Form to interact with the [Invoke Atomic Red Team PowerShell module](https://github,com/redcanaryco/invoke-atomicredteam). Users can run existing tests and create new tests. Note that PowerShell Core does not support Windows Forms, so this GUI is designed only to run on Windows.

### Prerequisites

Install [Invoke Atomic Red Team PowerShell module](https://github,com/redcanaryco/invoke-atomicredteam)

```powershell
IEX (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing);
Install-AtomicRedTeam
```

By default, the installer will download and install the execution framework to `C:\AtomicRedTeam`. See the [Invoke Atomic Red Team Wiki](https://github.com/redcanaryco/invoke-atomicredteam/wiki) for more details.

### Usage

From a PowerShell prompt, use 

```powershell
IEX (IWR "https://raw.githubusercontent.com/EmilyMWright/Invoke-AtomicRedTeam-GUI/master/IART_GUI.ps1" -UseBasicParsing); 
StartGUI
```

If your AtomicRedTeam folder is not in the default location, append `-AtomicFolderPath "yourpath\AtomicRedTeam"` to the command.

#### Running Tests

Tests are run using the Invoke-AtomicRedTeam [Invoke-AtomicTest module](https://github.com/redcanaryco/invoke-atomicredteam/blob/master/Public/Invoke-AtomicTest.ps1) by specifying the ATT&CK Technique number to which the test is mapped. 

- On the home page, type the technique (TNNNN) or use the **Browse...** button to navigate to the folder of the technique.
- Use the **Test** drop down to select a specific test (default 'All').
- Select an action from the drop down menu (for more details on the purpose of each action, peruse the [Invoke Atomic Red Team Wiki](https://github.com/redcanaryco/invoke-atomicredteam/wiki)).
- If you selected a specific test, you can edit the default input values in the **Edit default inputs** data grid.

**WARNING**

Executing atomic tests may leave your system in an undesirable state. You are responsible for understanding what a test does before executing. Ensure you have permission to test before you begin. It is recommended to set up a test machine for atomic test execution that is similar to the build in your environment. Be sure you have your collection/EDR solution in place, and that the endpoint is checking in and active.

#### Creating Tests

Tests are created using the Invoke-AtomicRedTeam [New-Atomic module](https://github.com/redcanaryco/invoke-atomicredteam/blob/master/Public/New-Atomic.ps1). Each new test must be added to an ATT&CK Technique (either existing or new).

- From the home page, click **Create Test**. You will be directed to a new window to specify the test parameters.
- Fill in [test parameters](#test-parameters). If your test will be similar to an existing test, you can pre-fill the form with parameters from an existing test. Type the technique (TNNNN) or use the **Browse...** button to navigate to the folder of the technique, then click **Load Test**. To reset all parameters, click **Clear**.
- Optionally, fill in [input parameters](#input_parameters) and click **Add Input**. To modify an input, select it in the **Input List**, make your changes and click **Update Input**. To remove it altogether, click **Remove Input**.
- Optionally, fill in [dependency parameters](#dependency_parameters) and click **Add Dependency**. To modify a dependency, select it in the **Dependency List**, make your changes and click **Update Dependency**. To remove it altogether, click **Remove Dependency**.
- Click **Create Test**. You will be directed to a new window to add the test to a technique.
- To create a new technique, fill in the [attack technique parameters](attack_technique_parameters) and click **Add test to new attack technique**. Alternatively, append the test to an exisitng technique. Type the technique (TNNNN) or use the **Browse...** button to navigate to the folder of the technique, then click **Add test to existing attack technique**.

### Parameter Details
#### Test Parameters

The minimum parameters are test name, test description, supported platforms, and either executor type and executor command, or executor steps. 

- **Test Name:** Specifies the name of the test that indicates how it tests the technique.
- **Test Description:** Specifies a long form description of the test. Markdown is supported.
- **Supported Platforms:** Specifies the OS/platform on which the test is designed to run. The following platforms are currently supported: Windows, macOS, Linux. (A single test can support multiple platforms)
- **Executor Type:** Specifies the the framework or application in which the test should be executed. The following executor types are currently supported: CommandPrompt, Sh, Bash, PowerShell.
    - **CommandPrompt:** The Windows Command Prompt, aka cmd.exe
    Requires the -ExecutorCommand argument to contain a multi-linescript that will be preprocessed and then executed by cmd.exe.
    - **PowerShell:** PowerShell
    Requires the -ExecutorCommand argument to contain a multi-line PowerShell scriptblock that will be preprocessed and then executed by powershell.exe
    - **Sh:** Linux's bourne shell
    Requires the -ExecutorCommand argument to contain a multi-line script that will be preprocessed and then executed by sh.
    - **Bash:** Linux's bourne again shell
    Requires the -ExecutorCommand argument to contain a multi-line script that will be preprocessed and then executed by bash.
- **Elevation Required:** Specifies that the test must run with elevated privileges.
- **Executor Command:** Specifies the command to execute as part of the atomic test. This should be specified when the atomic test can be executed in an automated fashion. (The Executor Type specified will dictate the command specified, e.g. PowerShell scriptblock code when the "PowerShell" Executor Type is specified.)
- **Executor Clean-up Command:** Specifies the command to execute if there are any artifacts that need to be cleaned up.
- **Executor Steps:** Specifies a manual list of steps to execute. This should be specified when the atomic test cannot be executed in an automated fashion, for example when GUI steps are involved that cannot be automated.
- **Input Arguments:** 
- **Dependencies:** Specifies dependencies that must be met prior to execution of an atomic test.
- **Dependency Executor Type:** Specifies an override execution type for dependencies. By default, dependencies are executed using the framework specified in Executor Type. In most cases, 'PowerShell' is specified as a dependency executor type when 'CommandPrompt' is specified as an executor type.

#### Input Parameters

- **Name:** Specifies the name of the input argument. This must be lowercase and can optionally, have underscores. Within executors and dependencies, reference the input using #{input_name}.
- **Description:** Specifies a human-readable description of the input argument.
- **Type:** Specifies the data type of the input argument. The following data types are supported: Path, Url, String, Integer, Float.
- **Default:** Specifies a default value for an input argument

#### Dependency Parameters

- **Description:** Specifies a human-readable description of the dependency. This should be worded in the following form: SOMETHING must SOMETHING
- **Prereq Command:** Specifies commands to check if prerequisites for running this test are met. For the "command_prompt" executor, if any command returns a non-zero exit code, the pre-requisites are not met. For the "powershell" executor, all commands are run as a script block and the script block must return 0 for success.
- **Get Prereq Command:** Specifies commands to meet this prerequisite or a message describing how to meet this prereq. More specifically, this command is designed to satisfy either of the following conditions:
    1) If a prerequisite is not met, perform steps necessary to satify the prerequisite. Such a command should be implemented when prerequisites can be satisfied in an automated fashion.
    2) If a prerequisite is not met, inform the user what the steps are to satisfy the prerequisite. Such a message should be presented to the user in the case that prerequisites cannot be satisfied in an automated fashion.

#### Attack Technique Parameters

- **Attack Technique:** Specifies one or more MITRE ATT&CK techniques that to which this technique applies. Per MITRE naming convention, an attack technique should start with "T" followed by a 4 digit number. The MITRE sub-technique format is also supported: TNNNN.NNN
- **DisplayName:** Specifies the name of the technique as defined by ATT&CK. Example: 'Audio Capture'

### License

This project is licensed under the terms of the MIT license. See [LICENSE.txt](https://github.com/EmilyMWright/Invoke-AtomicRedTeam-GUI/blob/master/LICENSE.txt)



