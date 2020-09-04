function resFile = gen_eval_files(track, gtFile, track_output_path, sequence_name)

gtInfo=parseCVML(gtFile);
frames = gtInfo.frameNums; 

docNode = com.mathworks.xml.XMLUtils.createDocument('result');
name_attribute = docNode.createAttribute('name');
name_attribute.setNodeValue(sequence_name);
docNode.getDocumentElement.setAttributeNode(name_attribute);

for i = frames

idx = find(track.fr == i+1);
cur_fr = i;

if isempty(idx)
    frame_node = docNode.createElement('frame');
    number_attribute = docNode.createAttribute('number');
    number_attribute.setNodeValue(num2str(cur_fr));
    frame_node.setAttributeNode(number_attribute);
    docNode.getDocumentElement.appendChild(frame_node);

    object_list_node = docNode.createElement('objectlist');
    frame_node.appendChild(object_list_node);  
else

frame_node = docNode.createElement('frame');
number_attribute = docNode.createAttribute('number');
number_attribute.setNodeValue(num2str(cur_fr));
frame_node.setAttributeNode(number_attribute);
docNode.getDocumentElement.appendChild(frame_node);

object_list_node = docNode.createElement('objectlist');
frame_node.appendChild(object_list_node);

for j = 1:length(idx)

object_node = docNode.createElement('object');
id_attribute = docNode.createAttribute('id');
id_attribute.setNodeValue(num2str(track.id(idx(j))));
object_node.setAttributeNode(id_attribute);
object_list_node.appendChild(object_node);

box_node = docNode.createElement('box');
h_attribute = docNode.createAttribute('h');
h_attribute.setNodeValue(num2str(track.h(idx(j))));
box_node.setAttributeNode(h_attribute);

h_attribute = docNode.createAttribute('w');
h_attribute.setNodeValue(num2str(track.w(idx(j))));
box_node.setAttributeNode(h_attribute);

h_attribute = docNode.createAttribute('xc');
h_attribute.setNodeValue(num2str(track.x_hat(idx(j))+track.w(idx(j))/2));
box_node.setAttributeNode(h_attribute);

h_attribute = docNode.createAttribute('yc');
h_attribute.setNodeValue(num2str(track.y_hat(idx(j))+track.h(idx(j))/2));
box_node.setAttributeNode(h_attribute);

object_node.appendChild(box_node);

end

end

end

resFile = [track_output_path sequence_name '.xml'];
xmlwrite(resFile,docNode);
