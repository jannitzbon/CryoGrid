# CryoGrid Community Model

This is the community version of *CryoGrid*, a numerical model to investigate land surface processes in permafrost environments. *CryoGrid* is implemented in MATLAB.



## Documentation

The documentation of the model is hosted on [ReadTheDocs](https://cryogrid-documentation.readthedocs.io/en/latest/). Some parts of the documentation have yet to be incorporated into ReadTheDocs and are currently provided in a separate [PDF](./CryoGrid_documentation.pdf).



## Repository structure and git workflow

This repository contains the code base of *CryoGrid*. The repository contains two major branches:

- The `master` branch hosts **stable versions** of the code base which have undergone various tests.
- The `develop` branch hosts the **latest version** of the code base which includes recent functionalities. It might, however, not have been extensively tested. 

We follow (more or less) the [git-flow](https://nvie.com/posts/a-successful-git-branching-model/) workflow to structure the repository and we recommend users and developers of *CryoGrid* to also stick to this workflow. Essentially, this means that new features are developed on dedicated `feature` branches which have the `develop` branch as their base. From time to time, sufficiently tested functionalities are merged from the `develop` branch into the `master` branch and these versions are tagged with a release number.



## Getting started as a *CryoGrid* user

In order to run the model, additional user-modifiable files need to be obtained from the repository [CryoGridExamples](https://github.com/CryoGrid/CryoGridExamples). See [this section](https://cryogrid-documentation.readthedocs.io/en/latest/source/Quick%20start.html#get-started-getting-code-and-examples-for-running-your-first-model) in the documentation for detailed instructions on how to set up the model code and how to run simulations.

If you only want to try out *CryoGrid* or use it without modifying the code base, you can `download` this repository by clicking on the button `Code > Download ZIP` and save and unzip it wherever you prefer. Alternatively, you can `clone` it to your local machine by using the command 

`$ git clone https://github.com/CryoGrid/CryoGrid.git /path/to/my/CryoGrid`, 

or by using [GitHub Desktop](https://desktop.github.com/).

If you consider to extensively use *CryoGrid* and to potentially contribute to its development, we strongly suggest to [sign up](https://github.com/join?ref_cta=Sign+up&ref_loc=header+logged+out&ref_page=%2F&source=header-home) for your own GitHub account and to create your own [Fork](https://guides.github.com/activities/forking/) of the repository using the **Fork** button in the top right corner. 



## Contributing as a *CryoGrid* developer

If you are already or want to become an active developer of *CryoGrid*, you will need to [sign up](https://github.com/join?ref_cta=Sign+up&ref_loc=header+logged+out&ref_page=%2F&source=header-home) for your own GitHub account and create your own [Fork](https://guides.github.com/activities/forking/) of the repository using the **Fork** button in the top right corner. 

You can then  `clone` the forked repository to your local computer:

`$ git clone https://github.com/YourGithubUserName/CryoGrid.git /path/to/my/CryoGrid`,

and start to work on the code. Remember to regularly take snapshots of your work by creating `commits`. 

Once you are happy with your developments, you can `push` changes from your local repository back to your forked repository on GitHub:

`$ git push origin develop`.

Finally, if you think the *CryoGrid* community would benefit from your implementations, you can create a **Pull request** on the GitHub website. While doing so, you need to choose the `develop` branch of the official *CryoGrid* code base repository as the `BASE` branch , and the branch with the changes you want to contribute as `COMPARE` branch. See [this tutorial](https://www.earthdatascience.org/courses/intro-to-earth-data-science/git-github/github-collaboration/how-to-submit-pull-requests-on-github/) for detailed instructions and examples on pull requests.

