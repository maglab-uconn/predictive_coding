# SRN

* __We made a jupyter notebook example to use SRN model. Please check [Train.ipynb](./SRN/Train.ipynb) and [Test.ipynb](./SRN/Test.ipynb)__

## Method
1. Go to `SRN` and run 'ipython'
    ```
    cd SRN
    ipython
    ```
2. Import model
    ```
    from SRN import Model, Sigmoid, Softmax, List_Test
    ```
3. Generate model
    ```
    new_Model = Model(
        hidden_Unit= <int>,
        output_Function= <Sigmoid or Softmax>,
        lexicon_File= <path>,
        additional_Lexicon_File= <path>,
        weight_File= <path>,
        use_Frequency= <bool>
        )
    ```

    * Parameters
        * `hidden_Unit`
            * The size of hidden units
        * `output_Function`
            * Determine output function
            * `Softmax` or `Sigmoid`
        * `lexicon_File`
            * The lexicon that the model uses by default
            * `ELP_groupData.csv` is an example
        * `additional_Lexicon_File`
            * Lexicon assuming further learning
            * `Novel_Lexicon_1.csv` and `Novel_Lexicon_2.csv` are examples.
        * `weight_File`
            * If you want load a pre-trained weight file, set the weight path
            * If not, set `None`
        * `use_Frequency`
            * If you want to use frequency information of lexicon, set `True`
            * Default is `False`
    
4. Train basic lexicon
    ```
    new_Model.Train(
        learning_Rate= <float>,
        max_Epoch= <int>,
        epoch_Batch_Size= <int>,
        mode='Normal',
        test_Pronunciation = <str>
        )
    ```

    * Parameters
        * `learning_Rate`
            * The learning rate while training.
        * `max_Epoch`
            * Determine the maximum training epoch.
        * `epoch_Batch_Size`
            * Determine the batch size of training.
            * After doing batch training, the weight will be saved.
        * `mode`
            * In basic lexicon training, this parameter is fixed 'Normal'
        * `test_Pronunciation`
            * Determine one phoneme string will be tested While training.

5. Train additional lexicon
    ```
    new_Model.Train(
        learning_Rate= <float>,
        max_Epoch= <int>,
        epoch_Batch_Size= <int>,
        mode='Addition',
        test_Pronunciation = <str>,
        initial_Epoch= <int>,
        tag= <str>,
        )
    ```
    
    * Parameters
        * `learning_Rate`
            * The learning rate while training.
            * Using lower value than basic lexicon training's is recommended.
        * `max_Epoch`
            * Determine the maximum training epoch.
        * `epoch_Batch_Size`
            * Determine the batch size of training.
            * After doing batch training, the weight will be saved.
        * `mode`
            * In basic lexicon training, this parameter is fixed 'Addition'
        * `test_Pronunciation`
            * Determine a phoneme string will be tested While training.
        * `initial_Epoch`
            * Set number the initial epoch.
            * This value does not affect the model's performance.
            * Using the last epoch of `Pre` training is recommended to manage easily.

6. Single phoneme string test
    1. Load both of two pre and post addition models.
        ```
        pre_Model = Model(
            hidden_Unit= <int>,
            output_Function= <Sigmoid or Softmax>,
            lexicon_File= <path>,
            additional_Lexicon_File= <path>,
            weight_File= <path>
            )    

        post_Model = Model(
            hidden_Unit= <int>,
            output_Function= <Sigmoid or Softmax>,
            lexicon_File= <path>,
            additional_Lexicon_File= <path>,
            weight_File= <path>
            )
        ```

        * `weight_File` is located in './Results/<Use_Frequency>/Weight'

    2. Test plotting
        ```
        pre_Model.Test_Plot(pronunciation= <str>, file_Suffix=<str>)
        post_Model.Test_Plot(pronunciation= <str>, file_Suffix=<str>)
        ```

        * Parameters
            * `test_Pronunciation`
                * Determine a phoneme string will be tested.
            * `file_Suffix`
                * Determine the suffix of exported file name

    * Result example  
    <img src= './Figures/SRN.Activation.Example.png' width= 30% height= 30% />
    <img src= './Figures/SRN.MSE.Example.png' width= 31.7% height= 31.7% />


7. Phase test
    1. Load both of two pre and post addition models.
        ```
        pre_Model = Model(
            hidden_Unit= <int>,
            output_Function= <Sigmoid or Softmax>,
            lexicon_File= <path>,
            additional_Lexicon_File= <path>,
            weight_File= <path>,
            use_Frequency= <bool>
            )    

        post_Novel1_Day1_Model = Model(
            hidden_Unit= <int>,
            output_Function= <Sigmoid or Softmax>,
            lexicon_File= <path>,
            additional_Lexicon_File= <path>,
            weight_File= <path>,
            use_Frequency= <bool>
            )
        
        post_Novel1_Day2_Model = Model(
            hidden_Unit= <int>,
            output_Function= <Sigmoid or Softmax>,
            lexicon_File= <path>,
            additional_Lexicon_File= <path>,
            weight_File= <path>,
            use_Frequency= <bool>
            )

        post_Novel2_Day1_Model = Model(
            hidden_Unit= <int>,
            output_Function= <Sigmoid or Softmax>,
            lexicon_File= <path>,
            additional_Lexicon_File= <path>,
            weight_File= <path>,
            use_Frequency= <bool>
            )
        
        post_Novel2_Day2_Model = Model(
            hidden_Unit= <int>,
            output_Function= <Sigmoid or Softmax>,
            lexicon_File= <path>,
            additional_Lexicon_File= <path>,
            weight_File= <path>,
            use_Frequency= <bool>
            )
        ```

        * `weight_File` is located in './Results/<Use_Frequency>/Weight'

    2. Type following command
        ```
        Phase_Test(
            pre_Model= pre_Model,
            post_Novel1_Day1_Model= post_Novel2_Day2_Model,
            post_Novel1_Day2_Model= post_Novel2_Day2_Model,
            post_Novel2_Day1_Model= post_Novel2_Day2_Model,
            post_Novel2_Day2_Model= post_Novel2_Day2_Model,
            tag= <str>,
            export_Path= <path>
            )
        ```

        * Result file is `<export_Path>/Result_Data<tag>.txt`.