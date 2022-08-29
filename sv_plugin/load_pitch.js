function getClientInfo() {
  return {
    "name" : "载入音高",
    "author" : "無波",
    "versionNumber" : 1,
    "minEditorVersion" : 67073
  };
}


function blick(meter){
	return SV.getProject().getTimeAxis().getBlickFromSeconds(meter/4) //44拍
}

function s_blick(second){
	return SV.getProject().getTimeAxis().getBlickFromSeconds(second)
}

function main() {
  //var N_sample=SV.showInputBox("N_sample","建议小于1000","50");
  //N_sample=parseInt(N_sample);
  
  var info = SV.getHostClipboard().split('\n');
  
  var onset = SV.getProject().getTimeAxis().getBlickFromSeconds(SV.getPlayback().getPlayhead());  
  var noteGroup = SV.getMainEditor().getCurrentTrack().getGroupReference(0).getTarget();
  /*for (count=0;count<N_sample;count++){
	  
	
	params=params+pinyin[t_pinyin]+" "+t_pitch.toString();
	
	for (i=0;i<5;i++){
		var targetParam = noteGroup.getParameter(paramNames[i]);
		t=Math.random();
		t=t*range_param[i][0]+(1-t)*range_param[i][1];
		targetParam.remove(blick(0.4+1.5*count),blick(1.6+1.5*count));
		targetParam.add(blick(0.45+1.5*count), t);
		targetParam.add(blick(1.55+1.5*count), t);
		params=params+" "+t.toString();
	}
	
	params=params+"\n";
  }*/
  info.splice(info.length-1);
  for (i=0;i<info.length;i++){
	  info[i]=info[i].split(' ');
	  for (j=0;j<info[i].length;j++){
		  info[i][j]=parseFloat(info[i][j]);		  
	  }
  }
  var targetParam = noteGroup.getParameter("pitchdelta");
  targetParam.removeAll();
  for (j=0;j<info.length;j++){
	targetParam.add(s_blick(info[j][0]),info[j][1]);
  }
  SV.showMessageBox("0,0",info[0][0]);
  SV.showMessageBox("0,1",info[0][1]);
}