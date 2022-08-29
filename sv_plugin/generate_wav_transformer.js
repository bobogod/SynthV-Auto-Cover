function getClientInfo() {
  return {
    "name" : "数据集生成_transformer",
    "author" : "無波",
    "versionNumber" : 1,
    "minEditorVersion" : 67073
  };
}


function blick(meter){
	return  SV.getProject().getTimeAxis().getBlickFromSeconds(meter/4) //44拍
}

function main() {
  var N_sample=SV.showInputBox("N_sample","建议小于1000","50");
  N_sample=parseInt(N_sample);
  
  
  
  const pinyin = ["ba","bo","bai","bei","bao","ban","ben","bang","beng","bi","bie","biao","bian","bin","bing","pa","po","pai","pao","pou","pan","pen","pang","peng","pi","pie","piao","pian","pin","ping","ma","mo","me","mai","mao","mou","man","men","mang","meng","mi","mie","miao","miu","mian","min","ming","fa","fo","fei","fou","fan","fen","fang","feng","da","de","dai","dei","dao","dou","dan","dang","deng","di","die","diao","diu","dian","ding","ta","te","tai","tao","tou","tan","tang","teng","ti","tie","tiao","tian","ting","na","nai","nei","nao","no","nen","nang","neng","ni","nie","niao","niu","nian","nin","niang","ning","la","le","lai","lei","lao","lou","lan","lang","leng","li","lia","lie","liao","liu","lian","lin","liang","ling","ga","ge","gai","gei","gao","gou","gan","gen","gang","geng","ka","ke","kai","kou","kan","ken","kang","keng","ha","he","hai","hei","hao","hou","hen","hang","heng","ji","jia","jie","jiao","jiu","jian","jin","jiang","jing","qi","qia","qie","qiao","qiu","qian","qin","qiang","qing","xi","xia","xie","xiao","xiu","xian","xin","xiang","xing","zha","zhe","zhi","zhai","zhao","zhou","zhan","zhen","zhang","zheng","cha","che","chi","chai","chou","chan","chen","chang","cheng","sha","she","shi","shai","shao","shou","shan","shen","shang","sheng","re","ri","rao","rou","ran","ren","rang","reng","za","ze","zi","zai","zao","zou","zang","zeng","ca","ce","ci","cai","cao","cou","can","cen","cang","ceng","sa","se","si","sai","sao","sou","san","sen","sang","seng","ya","yao","you","yan","yang","yu","ye","yue","yuan","yi","yin","yun","ying","wa","wo","wai","wei","wan","wen","wang","weng","wu"];
  const paramNames = ["tension","breathiness","voicing","gender","toneshift"];
  var range_pitch=[55,80];
  var range_param=[[-0.5,0.5],[-0.75,0.75],[0.2,1],[-0.1,0.1],[-400,400]] //limited gender
  var params=[];
    
  var prev_offset=0.5;	
  var noteGroup = SV.getMainEditor().getCurrentTrack().getGroupReference(0).getTarget();
  for (count=0;count<N_sample;count++){
	var note = SV.create("Note");
	var t_pinyin=Math.floor(Math.random()*pinyin.length);	
	note.setLyrics(pinyin[t_pinyin]);
	t=Math.random();
	t_pitch=Math.round(t*range_pitch[0]+(1-t)*range_pitch[1]);
	note.setPitch(t_pitch);
	
	params=params+prev_offset.toString()
	
	note.setOnset(blick(prev_offset));
    t=Math.floor(Math.random()*3)+1; //0.5-1.5 blick (4/4)	
	note.setDuration(blick(0.5*t));
	prev_offset=prev_offset+0.5*t;
	note.setAttributes({
		"dF0Left":0,
		"dF0Right":0,
		"dF0Vbr":0,
	})
	noteGroup.addNote(note);	  
	
	params=params+" "+pinyin[t_pinyin]+" "+t_pitch.toString();
	
	for (i=0;i<5;i++){
		var targetParam = noteGroup.getParameter(paramNames[i]);
		t=Math.random();
		t=t*range_param[i][0]+(1-t)*range_param[i][1];
		//targetParam.remove(blick(0.4+1.5*count),blick(1.6+1.5*count));
		//targetParam.add(blick(0.45+1.5*count), t);
		tt=Math.floor(Math.random()*4)+1; 
		t_time=prev_offset-0.2*tt;
		targetParam.add(blick(t_time), t);
		params=params+" "+t.toString()+"+"+t_time.toString();
	}
	
	params=params+"\n";
  }
  //SV.showMessageBox("params",params);
  
  
  //var fso=new ActiveXObject("Scripting.FileSystemObject");
  SV.setHostClipboard(params);
  
}