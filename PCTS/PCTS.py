import numpy as np
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt
from copy import deepcopy
import os

def Sub_Pronunciation_Generate(phoneme_String):
    return [phoneme_String[0:index] for index in range(1, len(phoneme_String))]

class Model:
    def __init__(self, lexicon_File= 'Pronunciation_Data.txt'):
        self.Load_Data(lexicon_File)
        self.parameter_Dict = {
            ('Input','Phoneme'): 1.0,
            ('Phoneme','Word'): 0.1,
            ('Word','Phoneme'): -0.05,
            'Decay': 0.1
            }

    def Load_Data(self, lexicon_File= 'Pronunciation_Data.txt'):
        with open (lexicon_File, "r") as f:
            readLines = f.readlines()
        self.word_Index_Dict = {line.strip() + '_': index for index, line in enumerate(readLines)} #'_' is the end token
        self.index_Word_Dict = {value: key for key, value in self.word_Index_Dict.items()}

        phoneme_Set = set()
        for word in self.word_Index_Dict.keys():
            phoneme_Set = phoneme_Set.union(set(word))

        self.phoneme_Index_Dict = {phoneme: index for index, phoneme in enumerate(sorted(list(phoneme_Set)))}
        self.index_Phoneme_Dict = {value: key for key, value in self.phoneme_Index_Dict.items()}

    def Test(self, phoneme_String, title_Suffix='', file_Suffix=''):
        print('Test: {}'.format(phoneme_String))

        activation_Dict = {
            ('Phoneme', -1): np.zeros((len(self.phoneme_Index_Dict))),
            ('Word', -1): np.zeros((len(self.word_Index_Dict)))
            }
        additional_Info_Dict = {}


        for location, current_Phoneme in enumerate(phoneme_String):
            additional_Info_Dict['Feedforward', location] = 0
            additional_Info_Dict['Feedback', location] = 0
            #P(t)
            activation_Dict['Phoneme', location] = np.zeros((len(self.phoneme_Index_Dict)))
            activation_Dict['Phoneme', location][self.phoneme_Index_Dict[current_Phoneme]] += self.parameter_Dict['Input','Phoneme']

            for word, word_Index in self.word_Index_Dict.items():
                if len(word) <= location:
                    continue
                activation_Dict['Phoneme', location][self.phoneme_Index_Dict[word[location]]] += activation_Dict['Word', location - 1][word_Index] * self.parameter_Dict['Word','Phoneme']

                if word[location] == current_Phoneme:
                    additional_Info_Dict['Feedback', location] += activation_Dict['Word', location - 1][word_Index] * self.parameter_Dict['Word','Phoneme']

            activation_Dict['Phoneme', location] = np.clip(activation_Dict['Phoneme', location], 0.0, 1.0)

            #W(t)
            activation_Dict['Word', location] = np.zeros((len(self.word_Index_Dict)))
            activation_Dict['Word', location] += activation_Dict['Word', location - 1]
            for word, word_Index in self.word_Index_Dict.items():
                if len(word) <= location:
                    activation_Dict['Word', location][self.word_Index_Dict[word]] -= self.parameter_Dict['Decay']
                    continue

                for phoneme, phoneme_Index in self.phoneme_Index_Dict.items():
                    if word[location] == phoneme:
                        activation_Dict['Word', location][self.word_Index_Dict[word]] += activation_Dict['Phoneme', location][phoneme_Index] * self.parameter_Dict['Phoneme','Word']

                        if word[location] == current_Phoneme:
                            additional_Info_Dict['Feedforward', location] += activation_Dict['Phoneme', location][phoneme_Index] * self.parameter_Dict['Phoneme','Word']

                if word[location] != current_Phoneme:
                    activation_Dict['Word', location][self.word_Index_Dict[word]] -= self.parameter_Dict['Decay']

            activation_Dict['Word', location] = np.clip(activation_Dict['Word', location], 0.0, 1.0)

        self.Draw_Graph(phoneme_String, activation_Dict, additional_Info_Dict, title_Suffix, file_Suffix)

    def Draw_Graph(self, phoneme_String, activation_Dict, additional_Info_Dict, title_Suffix='', file_Suffix=''):
        os.makedirs(os.path.join(os.getcwd(), 'Phoneme').replace("\\", "/"), exist_ok= True)
        os.makedirs(os.path.join(os.getcwd(), 'Word').replace("\\", "/"), exist_ok= True)
        os.makedirs(os.path.join(os.getcwd(), 'Phoneme_Sum').replace("\\", "/"), exist_ok= True)
        os.makedirs(os.path.join(os.getcwd(), 'Word_Sum').replace("\\", "/"), exist_ok= True)
        os.makedirs(os.path.join(os.getcwd(), 'Feedforward').replace("\\", "/"), exist_ok= True)
        os.makedirs(os.path.join(os.getcwd(), 'Feedback').replace("\\", "/"), exist_ok= True)
        
        os.makedirs(os.path.join(os.getcwd(), 'Word.Line10').replace("\\", "/"), exist_ok= True)
        
        phoneme_Array = np.transpose(np.vstack([activation_Dict['Phoneme', index] for index in range(len(phoneme_String))]))
        word_Array = np.transpose(np.vstack([activation_Dict['Word', index] for index in range(len(phoneme_String))]))        

        phoneme_Fig = plt.figure(figsize=(5, 5))
        plt.imshow(phoneme_Array, cmap="plasma", aspect='auto')
        plt.gca().set_xticks(range(len(phoneme_String)))
        plt.gca().set_xticklabels(phoneme_String)
        plt.gca().set_yticks(range(phoneme_Array.shape[0]))
        plt.gca().set_yticklabels(list(zip(*sorted([x for x in self.phoneme_Index_Dict.items()], key= lambda x: x[1])))[0])
        plt.title('Inserted: {}    Phoneme array{}'.format(phoneme_String, title_Suffix))
        plt.colorbar()
        plt.tight_layout()
        plt.savefig(
            os.path.join(os.getcwd(), 'Phoneme', '{}.Phoneme{}.PNG'.format(phoneme_String, file_Suffix)).replace("\\", "/"),
            )
        plt.close()

        word_Fig = plt.figure(figsize=(9, 24))
        plt.imshow(word_Array, cmap="plasma", aspect='auto')
        plt.gca().set_xticks(range(len(phoneme_String)))
        plt.gca().set_xticklabels(phoneme_String)
        plt.gca().set_yticks(range(word_Array.shape[0]))
        plt.gca().set_yticklabels(list(zip(*sorted([x for x in self.word_Index_Dict.items()], key= lambda x: x[1])))[0])
        plt.title('Inserted: {}    Word array{}'.format(phoneme_String, title_Suffix))
        plt.colorbar()
        plt.tight_layout()
        plt.savefig(
            os.path.join(os.getcwd(), 'Word', '{}.Word{}.PNG'.format(phoneme_String, file_Suffix)).replace("\\", "/"),
            )
        plt.close()

        phoneme_Sum_Fig = plt.figure(figsize=(5, 5))
        plt.plot(np.sum(phoneme_Array, axis=0))
        plt.gca().set_xticks(range(len(phoneme_String)))
        plt.gca().set_xticklabels(phoneme_String)
        plt.title('Inserted: {}    Phoneme sum{}'.format(phoneme_String, title_Suffix))
        plt.tight_layout()
        plt.savefig(
            os.path.join(os.getcwd(), 'Phoneme_Sum', '{}.Phoneme.Sum{}.PNG'.format(phoneme_String, file_Suffix)).replace("\\", "/"),
            )
        plt.close()

        word_Sum_Fig = plt.figure(figsize=(5, 5))
        plt.plot(np.sum(word_Array, axis=0))
        plt.gca().set_xticks(range(len(phoneme_String)))
        plt.gca().set_xticklabels(phoneme_String)
        plt.title('Inserted: {}    Word sum{}'.format(phoneme_String, title_Suffix))
        plt.tight_layout()
        plt.savefig(
            os.path.join(os.getcwd(), 'Word_Sum', '{}.Word.Sum{}.PNG'.format(phoneme_String, file_Suffix)).replace("\\", "/"),
            )
        plt.close()

        feedforward_Array = np.array([additional_Info_Dict['Feedforward', index] for index in range(len(phoneme_String))])
        feedback_Array = np.array([additional_Info_Dict['Feedback', index] for index in range(len(phoneme_String))])

        feedforward_Fig = plt.figure(figsize=(5, 5))
        plt.plot(feedforward_Array)
        plt.gca().set_xticks(range(len(phoneme_String)))
        plt.gca().set_xticklabels(phoneme_String)
        plt.title('Inserted: {}    Feedforward{}'.format(phoneme_String, title_Suffix))
        plt.tight_layout()
        plt.savefig(
            os.path.join(os.getcwd(), 'Feedforward', '{}.Feedforward{}.PNG'.format(phoneme_String, file_Suffix)).replace("\\", "/"),
            )
        plt.close()

        feedback_Fig = plt.figure(figsize=(5, 5))
        plt.plot(feedback_Array)
        plt.gca().set_xticks(range(len(phoneme_String)))
        plt.gca().set_xticklabels(phoneme_String)
        plt.title('Inserted: {}    Feedback{}'.format(phoneme_String, title_Suffix))
        plt.tight_layout()
        plt.savefig(
            os.path.join(os.getcwd(), 'Feedback', '{}.Feedback{}.PNG'.format(phoneme_String, file_Suffix)).replace("\\", "/"),
            )
        plt.close()


        word_Line_Fig = plt.figure(figsize=(5, 5))
        sorted_Indices = np.argsort(np.nanmax(word_Array, axis=1))[-10:]
        if phoneme_String in self.word_Index_Dict.keys():
            sorted_Indices = [self.word_Index_Dict[phoneme_String]] + list(reversed(np.delete(sorted_Indices, np.where(sorted_Indices == self.word_Index_Dict[phoneme_String]))[-9:]))

        for for_Target_Check, index in enumerate(sorted_Indices):
            plt.plot(
                word_Array[index],
                #color='red' if for_Target_Check == 0 and phoneme_String in self.word_Index_Dict.keys() else 'black',
                marker= 'o' if for_Target_Check == 0 and phoneme_String in self.word_Index_Dict.keys() else '',
                linestyle='solid' if for_Target_Check == 0 and phoneme_String in self.word_Index_Dict.keys() else 'dashed',
                linewidth= 1.5 if for_Target_Check == 0 and phoneme_String in self.word_Index_Dict.keys() else 1,
                label= self.index_Word_Dict[index]
                )
        plt.gca().set_xticks(range(len(phoneme_String)))
        plt.gca().set_xticklabels(phoneme_String)
        plt.title('Inserted: {}    Word sum{}'.format(phoneme_String, title_Suffix))
        plt.legend()
        plt.tight_layout()
        plt.savefig(
            os.path.join(os.getcwd(), 'Word.Line10', '{}.Word.Line{}.PNG'.format(phoneme_String, file_Suffix)).replace("\\", "/"),
            )
        plt.close()

if __name__ == '__main__':
    #new_New_Model = New_Model()
    
    #for word in new_New_Model.word_Index_Dict.keys():
    #    new_New_Model.Test(word)

    new_Model = Model(lexicon_File= 'Pronunciation_Data.add_simutal^.txt')
        
    for phoneme in new_Model.phoneme_Index_Dict.keys():
        if phoneme == '_':
            continue
        new_Model.Test('simuta{}^_'.format(phoneme))