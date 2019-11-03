
# NDL model Example

#Import
import numpy as np
from random import shuffle
import matplotlib.pyplot as plt
plt.style.use('ggplot')
import _pickle as pickle
import os

class String_to_Pattern:
    def __init__(self, index_Dict):
        self.index_Dict = index_Dict
    def Get_Pattern(self, letter_List):
        new_Pattern = np.zeros(shape=(len(letter_List),len(self.index_Dict)), dtype=np.uint8)
        new_Pattern[np.arange(len(letter_List)), [self.index_Dict[letter] for letter in letter_List]] = 1
        return new_Pattern

#Define Sigmoid
def Sigmoid(x):
    return 1 / (1 + np.exp(-1 * x))

#Define Softmax
def Softmax(x):
    return np.exp(x) / np.sum(np.exp(x), axis = 1, keepdims=True)    

#Define Tanh
def Tanh(x):
    return np.tanh(x)

#Define MSE
def MSE(target_Pattern, output_Activation):    
    return np.sqrt(np.mean((target_Pattern - output_Activation) ** 2, axis=1))

class Model:
    def __init__(
        self,
        hidden_Unit,
        output_Function,
        lexicon_File,
        additional_Lexicon_File = None,
        weight_File = None
        ):
        self.hidden_Unit = hidden_Unit        
        self.output_Function = output_Function        
        self.lexicon_File = lexicon_File
        self.additional_Lexicon_File = additional_Lexicon_File
        
        self.Pattern_Generate()
        self.Weight_Generate(weight_File)

    def Pattern_Generate(self):
        with open (self.lexicon_File, "r") as f:
            readLines = f.readlines()[1:]
        splited_ReadLine = [readLine.replace('"','').strip().split(",")[1:] for readLine in readLines]
        
        self.word_Index_Dict = {word.lower(): index for index, (word, _, _, _, _) in enumerate(splited_ReadLine)}
        self.pronunciation_Dict = {word.lower(): pronunciation for word, pronunciation, _, _, _ in splited_ReadLine}
        self.index_Word_Dict = {index: word for word, index in self.word_Index_Dict.items()}

        if self.additional_Lexicon_File is not None:
            with open (self.additional_Lexicon_File, "r") as f:
                readLines = f.readlines()[1:]
            splited_ReadLine = [readLine.replace('"','').strip().split(",")[1:] for readLine in readLines]

            self.additional_Word_Index_Dict = {word.lower(): index for index, (word, _, _, _, _) in enumerate(splited_ReadLine)}
            self.additional_Pronunciation_Dict = {word.lower(): pronunciation for word, pronunciation, _, _, _ in splited_ReadLine}
            self.additional_Index_Word_Dict = {index: word for word, index in self.additional_Word_Index_Dict.items()}

        self.phoneme_List = []
        for pronunciation in self.pronunciation_Dict.values():
            self.phoneme_List.extend(pronunciation)
        self.phoneme_List = sorted(list(set(self.phoneme_List)))
        self.phoneme_Index_Dict = {phoneme: index for index, phoneme in enumerate(self.phoneme_List)}
        self.string_to_Pattern = String_to_Pattern(self.phoneme_Index_Dict)
        
        print("Phoneme count:", len(self.phoneme_Index_Dict))
        print("Word count:", len(self.pronunciation_Dict))
        print("Total pronunciation length:", len([len(pronunciation) for pronunciation in self.pronunciation_Dict.values()]))
        
    def Weight_Generate(self, weight_File = None):
        unit_Size = len(self.phoneme_List)

        if weight_File is not None:
            with open(weight_File, "rb") as f:
                self.weight_Dict = pickle.load(f)
        else:
            self.weight_Dict = {}
            #Weight generate
            self.weight_Dict["Weight", "IH"] = (np.random.rand(unit_Size, self.hidden_Unit) * 2 - 1) * 0.01
            self.weight_Dict["Weight", "CH"] = (np.random.rand(self.hidden_Unit, self.hidden_Unit) * 2 - 1) * 0.01
            self.weight_Dict["Weight", "HO"] = (np.random.rand(self.hidden_Unit, unit_Size) * 2 - 1) * 0.01
        
            #Bias generate
            self.weight_Dict["Bias", "H"] = np.zeros((1, self.hidden_Unit))
            self.weight_Dict["Bias", "O"] = np.zeros((1, unit_Size))

        print("Weight Matrix IH shape:", self.weight_Dict["Weight", "IH"].shape)
        print("Weight Matrix IH shape:", self.weight_Dict["Weight", "CH"].shape)
        print("Weight Matrix HO shape:", self.weight_Dict["Weight", "HO"].shape)
        print("Bias Matrix H shape:", self.weight_Dict["Bias", "H"].shape)
        print("Bias Matrix O shape:", self.weight_Dict["Bias", "O"].shape)
        
    def Train(self, learning_Rate, max_Epoch, epoch_Batch_Size, mode="Normal", test_Pronunciation = 'fOrmj@l@'):
        if not os.path.exists(os.getcwd().replace("\\", "/") + "/Result/Weight"):
            os.makedirs(os.getcwd().replace("\\", "/") + "/Result/Weight")

        if mode == "Normal":
            word_Index_Dict = self.word_Index_Dict
            index_Word_Dict = self.index_Word_Dict
            pronunciation_Dict = self.pronunciation_Dict
        elif mode == "Addition":
            word_Index_Dict = self.additional_Word_Index_Dict
            index_Word_Dict = self.additional_Index_Word_Dict
            pronunciation_Dict = self.additional_Pronunciation_Dict
        elif mode == "Both":            
            word_Index_Dict = {key: value for key, value in self.word_Index_Dict.items()}
            word_Index_Dict.update({key: value + len(word_Index_Dict) for key, value in self.additional_Word_Index_Dict.items()})
            index_Word_Dict = {index: word for word, index in word_Index_Dict.items()}
            pronunciation_Dict = {key: value for key, value in self.pronunciation_Dict.items()}
            pronunciation_Dict.update(self.additional_Pronunciation_Dict)
        else:
            raise Exception("Unsupported mode")

        max_Cycle = np.sum([len(pronunciation) for pronunciation in pronunciation_Dict.values()]) - 1

        for start_Epoch in range(0, max_Epoch, epoch_Batch_Size):
            print("{} - {} Pattern string generating".format(start_Epoch, min(max_Epoch, start_Epoch + epoch_Batch_Size)))
            pattern_String_List = []
            for batch_Index in range(start_Epoch, min(max_Epoch, start_Epoch + epoch_Batch_Size)):
                #Training order shuffle
                training_Index_List = list(range(len(word_Index_Dict)))
                shuffle(training_Index_List)
                new_All_Pattern_String = "".join([pronunciation_Dict[index_Word_Dict[index]] for index in training_Index_List])                
                pattern_String_List.append(new_All_Pattern_String)
                
            context_Activation = np.zeros((len(pattern_String_List), self.hidden_Unit))
            for cycle in range(max_Cycle):
                input_Pattern_List, target_Pattern_List = zip(*[(pattern_String[cycle], pattern_String[cycle + 1]) for pattern_String in pattern_String_List])                
                input_Pattern = self.string_to_Pattern.Get_Pattern(input_Pattern_List)
                target_Pattern = self.string_to_Pattern.Get_Pattern(target_Pattern_List)                
                #Forward
                hidden_Activation = Tanh(
                    np.dot(input_Pattern, self.weight_Dict["Weight", "IH"]) + 
                    np.dot(context_Activation, self.weight_Dict["Weight", "CH"]) + 
                    self.weight_Dict["Bias", "H"])
                
                output_Activation = self.output_Function(np.dot(hidden_Activation, self.weight_Dict["Weight", "HO"]) + self.weight_Dict["Bias", "O"])
                
                #Error calculate
                mse = np.mean(MSE(target_Pattern, output_Activation))
                    
                output_Error  = target_Pattern - output_Activation
                if self.output_Function == Sigmoid:
                    output_Error *= output_Activation * (1 - output_Activation)
                elif self.output_Function == Tanh:
                    output_Error *= (1 - output_Activation ** 2)
                hidden_Error = np.dot(output_Error, np.transpose(self.weight_Dict["Weight", "HO"])) * (1 - hidden_Activation ** 2)
               
                #Weight renew
                self.weight_Dict["Weight", "IH"] += learning_Rate * np.dot(np.transpose(input_Pattern), hidden_Error)
                self.weight_Dict["Weight", "CH"] += learning_Rate * np.dot(np.transpose(context_Activation), hidden_Error)
                self.weight_Dict["Weight", "HO"] += learning_Rate * np.dot(np.transpose(hidden_Activation), output_Error)
                self.weight_Dict["Bias", "H"] += learning_Rate * np.sum(hidden_Error, axis=0, keepdims=True)
                self.weight_Dict["Bias", "O"] += learning_Rate * np.sum(output_Error, axis=0, keepdims=True)

                #Context renew
                context_Activation = hidden_Activation

                print("Mode: {}    Epoch: {} - {}    Cycle: {}    MSE: {}".format(mode, start_Epoch, min(max_Epoch, start_Epoch + epoch_Batch_Size), cycle, mse))

            with open(os.getcwd().replace("\\", "/") + "/Result/Weight/Weight.M_{}.E_{}.pickle".format(mode, min(max_Epoch, start_Epoch + epoch_Batch_Size)), "wb") as f:
                pickle.dump(self.weight_Dict, f, protocol=2)
            self.Test(test_Pronunciation, file_Suffix=".M_{}.E_{}".format(mode, min(max_Epoch, start_Epoch + epoch_Batch_Size)))
            
    def Test(self, pronunciation, file_Suffix=""):
        gagnepain_Error_List = []
        mse_List = []
        output_Activation_List = []

        context_Activation = np.zeros((1, self.hidden_Unit))
        for cycle in range(len(pronunciation) - 1):            
            input_Pattern = self.string_to_Pattern.Get_Pattern([pronunciation[cycle]])
            target_Pattern = self.string_to_Pattern.Get_Pattern([pronunciation[cycle + 1]])                
            #Forward
            hidden_Activation = Tanh(
                np.dot(input_Pattern, self.weight_Dict["Weight", "IH"]) + 
                np.dot(context_Activation, self.weight_Dict["Weight", "CH"]) + 
                self.weight_Dict["Bias", "H"])
            output_Activation = self.output_Function(np.dot(hidden_Activation, self.weight_Dict["Weight", "HO"]) + self.weight_Dict["Bias", "O"])            

            #Error calculate
            gagnepain_Error = np.sum(np.abs(target_Pattern - output_Activation))
            mse = np.mean(MSE(target_Pattern, output_Activation))

            #Context renew
            context_Activation = hidden_Activation

            gagnepain_Error_List.append(gagnepain_Error)
            mse_List.append(mse)
            output_Activation_List.append(output_Activation)
        
        self.Display_Result_Graph(pronunciation, mse_List, output_Activation_List, suffix=file_Suffix)

    def Test_Temp(self, pronunciation, initial_Context = None, file_Suffix=""):
        gagnepain_Error_List = []
        mse_List = []

        ih_Stroage_List = []
        ch_Stroage_List = []
        ho_Stroage_List = []
        context_Activation_List = []
        hidden_Activation_List = []
        output_Activation_List = []
        

        context_Activation = initial_Context if not initial_Context is None else np.random.rand(1, self.hidden_Unit)
        for cycle in range(len(pronunciation) - 1):            
            input_Pattern = self.string_to_Pattern.Get_Pattern([pronunciation[cycle]])
            target_Pattern = self.string_to_Pattern.Get_Pattern([pronunciation[cycle + 1]])                
            #Forward
            ih_Stroage = np.dot(input_Pattern, self.weight_Dict["Weight", "IH"])
            ch_Stroage = np.dot(context_Activation, self.weight_Dict["Weight", "CH"])
            hidden_Activation = Tanh(
                ih_Stroage + 
                ch_Stroage + 
                self.weight_Dict["Bias", "H"])
            ho_Stroage = np.dot(hidden_Activation, self.weight_Dict["Weight", "HO"])
            output_Activation = self.output_Function(ho_Stroage + self.weight_Dict["Bias", "O"])            

            #Error calculate
            gagnepain_Error = np.sum(np.abs(target_Pattern - output_Activation))
            mse = np.mean(MSE(target_Pattern, output_Activation))
                        
            gagnepain_Error_List.append(gagnepain_Error)
            mse_List.append(mse)
            
            ih_Stroage_List.append(ih_Stroage)
            ch_Stroage_List.append(ch_Stroage)
            ho_Stroage_List.append(ho_Stroage)
            context_Activation_List.append(context_Activation)
            hidden_Activation_List.append(hidden_Activation)
            output_Activation_List.append(output_Activation)

            #Context renew
            context_Activation = hidden_Activation
        
        return gagnepain_Error_List, mse_List, ih_Stroage_List, ch_Stroage_List, ho_Stroage_List, context_Activation_List, hidden_Activation_List, output_Activation_List

    def Display_Result_Graph(self, pronunciation, mse_List, output_Activation_List, suffix=""):
        if not os.path.exists(os.getcwd().replace("\\", "/") + "/Result/MSE_Plot"):
            os.makedirs(os.getcwd().replace("\\", "/") + "/Result/MSE_Plot")
        if not os.path.exists(os.getcwd().replace("\\", "/") + "/Result/Activation_Plot"):
            os.makedirs(os.getcwd().replace("\\", "/") + "/Result/Activation_Plot")

        fig = plt.figure(figsize=(6, 6))        
        plt.plot(mse_List)
        plt.title("MSE Flow    Pronunciation: {}".format(pronunciation))
        plt.xlabel('Cycle')
        plt.ylabel('MSE')
        plt.gca().set_xticks(range(len(pronunciation) - 1))
        plt.gca().set_xticklabels(["{}({})".format(index, phoneme) for index, phoneme in enumerate(pronunciation[1:])])
        plt.gca().set_ylim([0, 1])
        plt.savefig(
            os.getcwd().replace("\\", "/") + "/Result/MSE_Plot/MSE{}.png".format(suffix),
            bbox_inches='tight'
            )
        plt.close(fig)

        fig = plt.figure(figsize=(10, 10))
        plt.imshow(
            np.transpose(np.vstack(output_Activation_List)), 
            cmap="plasma", 
            aspect='auto', 
            origin='upper', 
            interpolation='none', 
            vmin= 0, 
            vmax= 1
            )
        plt.xlabel("Phoneme units")
        plt.ylabel("Cycle(Target)")
        plt.gca().set_xticks(range(len(pronunciation) - 1))
        plt.gca().set_xticklabels(["{}({})".format(index, phoneme) for index, phoneme in enumerate(pronunciation[1:])])
        plt.gca().set_yticks(range(len(self.phoneme_List)))
        plt.gca().set_yticklabels(self.phoneme_List)
        plt.title("Phoneme Activation Flow    Pronunciation: {}".format(pronunciation))
        plt.colorbar()
        plt.savefig(
            os.getcwd().replace("\\", "/") + "/Result/Activation_Plot/Activation{}.png".format(suffix),
            bbox_inches='tight'
            )
        plt.close(fig)

def List_Test(pre_Model, post_Model, phoneme_List):
    word_Dict = {}
    with open("Test_Lexicon.txt", "r") as f:
        for readLine in f.readlines()[1:]:
            word, original, novel, nonword  = readLine.strip().split("\t") 
            word_Dict[word, "Original"] = original
            word_Dict[word, "Novel"] = novel
            word_Dict[word, "Nonword"] = nonword        

    column_Name_List = [
        "Position",
        "Original",
        "Actual",
        "Phase",
        "Type",
        "Activation",
        "Gagnepain_Error",
        "MSE",
        "IxW",
        "CxW",
        "HxW",
        "Context",
        "Hidden",
        "Hidden_Abs",
        "Output"
        ]

    extract_List = ["\t".join(column_Name_List)]

    initial_Context_Dict = {
        'Pre': np.random.rand(1, pre_Model.hidden_Unit),
        'Post': np.random.rand(1, post_Model.hidden_Unit)
        }    
    for (word, type), pattern in word_Dict.items():
        for phase, model in [("Pre", pre_Model), ("Post", post_Model)]:
            gagnepain_Error_List, mse_List, ih_Stroage_List, ch_Stroage_List, ho_Stroage_List, context_Activation_List, hidden_Activation_List, output_Activation_List = model.Test_Temp(pattern, initial_Context_Dict[phase])
            for position, phoneme in enumerate(pattern[1:]):
                new_Line = []
                new_Line.append(str(position + 1))
                new_Line.append(word_Dict[word, "Original"])
                new_Line.append(word_Dict[word, type])
                new_Line.append(phase)
                new_Line.append(type)
                new_Line.append(str(output_Activation_List[position][0, phoneme_List.index(phoneme)]))
                new_Line.append(str(gagnepain_Error_List[position]))
                new_Line.append(str(mse_List[position]))
                new_Line.append(str(np.sum(ih_Stroage_List[position][0])))
                new_Line.append(str(np.sum(ch_Stroage_List[position][0])))
                new_Line.append(str(np.sum(ho_Stroage_List[position][0])))
                new_Line.append(str(np.sum(context_Activation_List[position][0])))
                new_Line.append(str(np.sum(hidden_Activation_List[position][0])))
                new_Line.append(str(np.sum(np.abs(hidden_Activation_List[position][0]))))                
                new_Line.append(str(np.sum(output_Activation_List[position][0])))
                extract_List.append("\t".join(new_Line))

            initial_Context_Dict[phase] = hidden_Activation_List[-1]

    with open(os.getcwd().replace("\\", "/") + "/Result/Result_Data.txt", "w") as f:
        f.write("\n".join(extract_List))

if __name__ == "__main__":
    #new_SRN_Model = SRN_Model(
    #    hidden_Unit=200,
    #    output_Function=Softmax,    #Function is first-class object
    #    lexicon_File='ELP_groupData.csv',
    #    additional_Lexicon_File='Novel_Lexicon.csv',        
    #    weight_File=os.getcwd().replace("\\", "/") + "/Result/Weight/Weight.M_Normal.E_10000.pickle"
    #    )
    #new_SRN_Model.Training(learning_Rate=0.0001, max_Epoch = 100, epoch_Batch_Size=10, mode="Addition", test_Pronunciation='fOrmj@bo')


    pre_SRN_Model = Model(
        hidden_Unit=200,
        output_Function=Softmax,    #Function is first-class object
        lexicon_File='ELP_groupData.csv',
        additional_Lexicon_File='Novel_Lexicon.csv',        
        weight_File=os.getcwd().replace("\\", "/") + "/Result/Weight/Weight.M_Normal.E_10000.pickle"
        )    

    post_SRN_Model = Model(
        hidden_Unit=200,
        output_Function=Softmax,    #Function is first-class object
        lexicon_File='ELP_groupData.csv',
        additional_Lexicon_File='Novel_Lexicon.csv',
        weight_File=os.getcwd().replace("\\", "/") + "/Result/Weight/Weight.M_Addition.E_50.pickle"
        )    
    phoneme_List = pre_SRN_Model.phoneme_List
    if not all([phoneme_List[index] == post_SRN_Model.phoneme_List[index] for index in range(len(phoneme_List))]):
        assert False

    List_Test(pre_SRN_Model, post_SRN_Model, phoneme_List)