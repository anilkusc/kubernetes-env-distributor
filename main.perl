#!/usr/bin/perl

#perl -MCPAN -e 'install YAML::Tiny'
use YAML::Tiny;
#take the yaml files 
@files = glob( $dir . './*' );
@yamls = grep(/yaml/, @files); 
#
$dirname ="./newdir/";
mkdir $dirname, 0755;

#if secret does not specified it is secrets.yaml by default 
$secret_file=@ARGV[0];
if ( !$secret_file ){
   $secret_file="secrets.yaml"; 
}
#Open the file 
$yaml_secret = YAML::Tiny->read( $secret_file ); 
$root = $yaml_secret->[0]->{stringData};
@data_structures = Dump($root);
##Delete the --- 
@data_structures[0] = substr(@data_structures[0], 4);
##convert to string array
@fields = split(/\n/, @data_structures[0]);
@value_array = (); 
for (@fields){
@values =  split(/:/, $_);
$value = @values[0];
push(@value_array, $value);
}

#print is_it_available("test2.yaml",\@value_array);
#add_env("test2.yaml",\@value_array,0,"secrets.yaml");
#We have our env variables as array

add_value("test3.yaml",1,"anil","secrets.yaml");
#TODO:after reformat yaml it is converting int to string.Prevent this.
#TODO:reformat it for kubernets yaml
#TODO:include(if there is value in include list only append it) and exclude list for yaml files
#TODO:include and exclude list for stringData in secrets.yaml



#create format
#format FROMSECRET =
#- name: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  
#$val1
#  valueFrom:
#    secretKeyRef:
#      name: common
#      key: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# $val2   
#.#

#open(FILE, ">file.txt"); 
#select FILE; 
##$~ = FROMSECRET; 
#for(@value_array){ 
#$val1 = $_;
#$val2 = $_; 
#$~ = 'FROMSECRET';
#write;
#}
#close FILE; 

sub check_kind{
  my $yaml_kind =  YAML::Tiny->read( @_[0] );
  my $i=0;
  @indexes=();
  @kinds=( "Deployment" , "StatefulSet" , "Pod" , "CronJob" , "Job");
  while($yaml_kind->[$i]) { 
 
  foreach $kind (@kinds) {
  
  my $check_kind = YAML::Tiny->new( { kind => $kind } );
  #check if it is valid.Deployment ,StatefulSet...
  if ( $check_kind->[0]->{kind} eq $yaml_kind->[$i]->{kind} ) {
  push(@indexes, $i);
   
  }
}
$i++;  
}
return @indexes; 
}

sub check_isthere_env{
   my $yaml =  YAML::Tiny->read( @_[0] );

   if($yaml->[$_[1]]->{spec}->{template}->{spec}->{containers}->[0]->{env}){ 
   return 1;
   } else{
   return 0;
   } 
}  
 
sub check_dublicated_env{
   my $yaml =  YAML::Tiny->read( @_[0] );
   my $controller = YAML::Tiny->new( { name => @_[1] } );
   my $i=0;
   while($yaml->[$_[2]]->{spec}->{template}->{spec}->{containers}->[0]->{env}->[$i]){

   if($yaml->[$_[2]]->{spec}->{template}->{spec}->{containers}->[0]->{env}->[$i]->{name} eq $controller->[0]->{name}){ 
   return 1;
   }
   $i++;
   }
   return 0; 
}
  
sub is_it_available{
my @value_array = @{$_[1]};
my @valid_kinds = check_kind(@_[0]);
#return -1,0,1
foreach $valid_kind (@valid_kinds) {

 if(check_isthere_env(@_[0], $valid_kind )){
    foreach $value (@value_array){
    if(check_dublicated_env(@_[0], $value , $valid_kind)){
       return 0;#there is same value on the env section.do nothing  
     }else{
       return 1;#there is env section and there is not same value on env section.add new value.
     }
     
     }
 }else{
    return -1;#start add_env subroutine
 }


} 
return 1;
} 

sub add_env{

  #yaml,value_array,indexes_for_yaml_document,secret_file
  my $yaml =  YAML::Tiny->read( @_[0] );
  my @value_array = @{$_[1]};
  my $yaml_secret = YAML::Tiny->read( @_[3] );
  my $i=0; 
  foreach $value (@value_array){ 
       
  $yaml->[@_[2]]->{spec}->{template}->{spec}->{containers}->[0]->{env};
  $yaml->[@_[2]]->{spec}->{template}->{spec}->{containers}->[0]->{env}->[$i]->{name} = $value;
  $yaml->[@_[2]]->{spec}->{template}->{spec}->{containers}->[0]->{env}->[$i]->{valueFrom}->{secretKeyRef}->{name} = $yaml_secret->[0]->{metadata}->{name};
  $yaml->[@_[2]]->{spec}->{template}->{spec}->{containers}->[0]->{env}->[$i]->{valueFrom}->{secretKeyRef}->{key} = $value ;       
  $yaml->write( $dirname . @_[0] );
  $i++;
  }
  } 

sub add_value{
 
  #yaml_file,yaml_indexes,value,secret
  my $yaml =  YAML::Tiny->read( @_[0] );
  my $yaml_secret = YAML::Tiny->read( @_[3] );
  my $value =  @_[2];
  my $i=0;


  while($yaml->[@_[1]]->{spec}->{template}->{spec}->{containers}->[0]->{env}->[$i]){
    $i++;
  } 

  $yaml->[@_[1]]->{spec}->{template}->{spec}->{containers}->[0]->{env}->[$i]->{name} = $value;
  $yaml->[@_[1]]->{spec}->{template}->{spec}->{containers}->[0]->{env}->[$i]->{valueFrom}->{secretKeyRef}->{name} = $yaml_secret->[0]->{metadata}->{name};
  $yaml->[@_[1]]->{spec}->{template}->{spec}->{containers}->[0]->{env}->[$i]->{valueFrom}->{secretKeyRef}->{key} = $value ;       
  $yaml->write( $dirname . @_[0] );

} 
