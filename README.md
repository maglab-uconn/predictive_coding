# Predictive_coding
Implementation of several predictive coding models

# Gagnepain 2012
__※To Monica: I think you have a bug fix version. Please modify the ['L67-L83'](./Gagnepain2012/Gagnepain2012.py#L67-L83) section to match your bug fix version.__

```
Gagnepain, P., Henson, R. N., & Davis, M. H. (2012). Temporal predictive codes for spoken words in auditory cortex. Current Biology, 22(7), 615-621.
```

## Method
1. Go to `Gagnepain2012` and run 'ipython'
    ```
    cd Gagnepain2012
    ipython
    ```

2. Import model
    ```
    from Gagnepain2012 import Model
    ```

3. Generate model
    ```    
    new_Model = Model(
        lexicon_File= <path>,
        additional_Lexicon_File= <path>
        )
    ```
        
    * Parameters
        * `lexicon_File`
            * The lexicon that the model uses by default
            * 'ELP_groupData.csv' is an example
        * `additional_Lexicon_File`
            * Lexicon assuming further learning
            * 'Novel_Lexicon.csv' is an example

4. Test
    ```
    new_Model.Test(phoneme_String= <str>)
    ```

    * Result example  
    <img src= './Figures/Gagnepain2012.Example.png' width= 50% height= 50% />
        
# SRN

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
        weight_File= <path>
        )
    ```

    * Parameters
        * `hidden_Unit`
            * The size of hidden units
        * `output_Function`
            * Determine output function
            * Softmax or Sigmoid
        * `lexicon_File`
            * The lexicon that the model uses by default
            * 'ELP_groupData.csv' is an example
        * `additional_Lexicon_File`
            * Lexicon assuming further learning
            * 'Novel_Lexicon.csv' is an example
        * `weight_File`
            * If you want load a pre-trained weight file, set the weight path
            * If not, set 'None'
    
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

5. Train additional lexicion
    ```
    new_Model.Train(
        learning_Rate= <float>,
        max_Epoch= <int>,
        epoch_Batch_Size= <int>,
        mode='Addition',
        test_Pronunciation = <str>
        )
    ```
    
    * Parameters
        * `learning_Rate`
            * The learning rate while training.
            * Lower value than basic lexicon training's is recommended.
        * `max_Epoch`
            * Determine the maximum training epoch.
        * `epoch_Batch_Size`
            * Determine the batch size of training.
            * After doing batch training, the weight will be saved.
        * `mode`
            * In basic lexicon training, this parameter is fixed 'Addition'
        * `test_Pronunciation`
            * Determine a phoneme string will be tested While training.

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

        * `weight_File` is located in './Result/Weight'

    2. Test
        ```
        pre_Model.Test(pronunciation= <str>, file_Suffix=<str>)
        post_Model.Test(pronunciation= <str>, file_Suffix=<str>)
        ```

        * Parameters
            * `test_Pronunciation`
                * Determine a phoneme string will be tested.
            * `file_Suffix`
                * Determine the suffix of exported file name

    * Result example  
    <img src= './Figures/SRN.Activation.Example.png' width= 30% height= 30% />
    <img src= './Figures/SRN.MSE.Example.png' width= 31.7% height= 31.7% />


7. Phoneme string list test
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

        * `weight_File` is located in './Result/Weight'

    2. Type following command
        ```
        List_Test(
            pre_Model= pre_Model,
            post_Model= post_Model,
            phoneme_List= <list of str>
            )
        ```

        * `phoneme_List`
            * The list of phoneme string which you want to test

        * Result file is `'./Result/Result_Data.txt'`.
            

# PCTS (Predictive Coding Time Specific) model
## Structure  
<img src= './Figures/PCTS/Structure.png' width= 20% height= 20% />  

## Method
1. Go to `PCTS` and run 'ipython'
    ```
    cd PCTS
    ipython
    ```

2. Import model
    ```
    from PCTS import Model
    ```

3. Generate model
    ```
    new_Model = Model(
        lexicon_File= <path>
        )
    ```
        
    * Parameters
        * `lexicon_File`
            * The lexicon that the model uses by default
            * 'Pronunciation_Data.txt' is an example

4. Test
    ```
    new_Model.Test(
        phoneme_String= <str>,
        title_Suffix= <str>,
        file_Suffix= <str>
        )
    ```

5. Result examples

* Phoneme
    * Activation of all phonemes at each time step
    * Example  
    <img src= './Figures/PCTS/b^s.Phoneme.PNG' width= 30% height= 30% />
* Word
    * Activation of all words at each time step
    * Example  
    <img src= './Figures/PCTS/b^s.Word.PNG' width= 30% height= 30% />
* Phoneme sum
    * Activation sum of all phonemes at each time step
    * Example  
    <img src= './Figures/PCTS/b^s.Phoneme.Sum.PNG' width= 30% height= 30% />
* Word sum
    * Activation sum of all words at each time step
    * Example  
    <img src= './Figures/PCTS/b^s.Word.Sum.PNG' width= 30% height= 30% />
* Word line10
    * Activation flow of top10 words
    * Example  
    <img src= './Figures/PCTS/b^s.Word.Line.PNG' width= 30% height= 30% />
* Feedforward
    * For each time step, the sum of the impact of the word layer by the entered phoneme
    * Example  
    <img src= './Figures/PCTS/b^s.Feedforward.PNG' width= 30% height= 30% />
* Feedback
    * For each time step, the sum of the impact of the phoneme layer by the previous step's activation of words that the phoneme of the previous step is the same as the currently entered phoneme
    * Example  
    <img src= './Figures/PCTS/b^s.Feedback.PNG' width= 30% height= 30% />

# PCTI (Predictive Coding Time Invariant) model

## Structure
<img src= './Figures/PCTI/Structure.png' width= 20% height= 20% />  

* Equation  
<img src= './Figures/PCTI/Equations.png' width= 30% height= 30% />

    * *i* is a phoneme. *j* is a word. *P* is activation of phoneme. *L* is activation of word. *t* is time step. *length(j)* is a function of word length. Ex) len(b^s) = 3.
    * Current parameters
        * *W<sub>IP</sub>*=1.0 , *W<sub>PL</sub>*=0.1 , *W<sub>LP</sub>*=-0.1 , *W<sub>length</sub>*=0.01 , *W<sub>sensitivity</sub>*=0.5 , *W<sub>decay</sub>*=-0.1

## Method
1. Go to `PCTI` and run 'ipython'
    ```
    cd PCTI
    ipython
    ```
2. Import model
    ```
    from PCTI import Model
    ```
3. Generate model
    ```
    new_Model = Model(
        lexicon_File= <path>
        )
    ```        
    * Parameters
        * `lexicon_File`
            * The lexicon that the model uses by default
            * 'Pronunciation_Data.txt' is an example
4. Test
    ```
    new_Model.Test(
        phoneme_String= <str>,
        title_Suffix= <str>,
        file_Suffix= <str>
        )
    ```

    * In the `phoneme_String`, please add '_'(end token) at the end of phoneme string. If you want to test 'b^s', please use 'b^s_'.
5. Result examples
* Phoneme
    * Activation of all phonemes at each time step
    * Example  
    <img src= './Figures/PCTI/b^s_.Phoneme.PNG' width= 30% height= 30% />
* Word
    * Activation of all words at each time step
    * Example  
    <img src= './Figures/PCTI/b^s_.Word.PNG' width= 30% height= 30% />
* Phoneme sum
    * Activation sum of all phonemes at each time step
    * Example  
    <img src= './Figures/PCTI/b^s_.Phoneme.Sum.PNG' width= 30% height= 30% />
* Word sum
    * Activation sum of all words at each time step
    * Example  
    <img src= './Figures/PCTI/b^s_.Word.Sum.PNG' width= 30% height= 30% />
* Word line10
    * Activation flow of top10 words
    * Example  
    <img src= './Figures/PCTI/b^s_.Word.Line.PNG' width= 30% height= 30% />
* Feedforward
    * For each time step, the sum of the impact of the word layer by the entered phoneme
    * Example  
    <img src= './Figures/PCTI/b^s_.Feedforward.PNG' width= 30% height= 30% />
* Feedback
    * For each time step, the sum of the impact of the phoneme layer by the previous step's activation of words that the phoneme of the previous step is the same as the currently entered phoneme
    * Example  
    <img src= './Figures/PCTI/b^s_.Feedback.PNG' width= 30% height= 30% />