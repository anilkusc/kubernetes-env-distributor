#!/usr/bin/perl

#perl -MCPAN -e 'install YAML::Tiny'
use YAML::Tiny;

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

#take the yaml files 
@files = glob( $dir . './*' );
@yamls = grep(/yaml/, @files);
foreach $yaml (@yamls){
  $yaml = substr($yaml,2);
}

foreach $yaml (@yamls) {

@indexes = check_kind($yaml);

foreach $index (@indexes) {
  
if(check_isthere_env($yaml,$index)){

my @filtered_array = check_dublicated_env($yaml,\@value_array,$index);

add_value($yaml,$secret_file,\@filtered_array,$index);

}else{
  add_env($yaml,\@value_array,$index,$secret_file);
}
}

system('perl', '-i', '-pe', 's/\'//g',$dirname . $yaml );

}

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
  }else{next;}

}
$i++;  
}
return @indexes; 
}

sub check_isthere_env{
   my $yaml =  YAML::Tiny->read( @_[0] );
   my $check = Dump($yaml->[@_[1]]->{spec}->{template}->{spec}->{containers});  
       if($check =~ m/env:/ ){ 
       return 1;
       } else{
       return 0;
       }
}  

#yaml,values_array,indexes 
sub check_dublicated_env{
   my $yaml =  YAML::Tiny->read( @_[0] );
   my @control_values = @{$_[1]};
   my @new_values = (); 
   
    foreach $value (@control_values){
      my $controller = YAML::Tiny->new( { name => $value } );    
      my $is_duplicated = 0; 
      my $i=0;

      while($yaml->[$_[2]]->{spec}->{template}->{spec}->{containers}->[0]->{env}->[$i]){
        if($yaml->[$_[2]]->{spec}->{template}->{spec}->{containers}->[0]->{env}->[$i]->{name} eq $controller->[0]->{name}){ 
         $is_duplicated = 1 ; 
         last;
        } 
        $i++;
      }
      if($is_duplicated == 0){
        push(@new_values,$value);
      }
    }
    return @new_values;
}
  
sub is_it_available{

my $value = @_[1];
my @valid_kinds = check_kind(@_[0]);

foreach $valid_kind (@valid_kinds) {
    if(check_dublicated_env(@_[0], $value , $valid_kind)){
       return 0;#there is same value on the env section.do nothing      
     }
}
return 1;#there is env section and there is not same value on env section.add new value. 
} 

sub add_env{

  #yaml,value_array,indexes_for_yaml_document,secret_file
  my $yaml =  YAML::Tiny->read( @_[0] );
  my @value_array = @{$_[1]};
  my $yaml_secret = YAML::Tiny->read( @_[3] );
  my $i=0;

  foreach $value (@value_array){ 
      
  $yaml->[@_[2]]->{spec}->{template}->{spec}->{containers}->[0]->{env}->[$i]->{name} = $value;
  $yaml->[@_[2]]->{spec}->{template}->{spec}->{containers}->[0]->{env}->[$i]->{valueFrom}->{secretKeyRef}->{name} = $yaml_secret->[0]->{metadata}->{name};
  $yaml->[@_[2]]->{spec}->{template}->{spec}->{containers}->[0]->{env}->[$i]->{valueFrom}->{secretKeyRef}->{key} = $value;
  $yaml->write( $dirname . @_[0] );
  $i++;
  }
  } 

sub add_value{

  #yaml_file,value_array,secret
  my $yaml =  YAML::Tiny->read( @_[0] );
  my $yaml_secret = YAML::Tiny->read( @_[1] );
  my @my_array = @{$_[2]};
  my $i=0;
  while($yaml->[@_[3]]->{spec}->{template}->{spec}->{containers}->[0]->{env}->[$i]){
    $i++;
    }

foreach $value (@my_array) {
  $yaml->[@_[3]]->{spec}->{template}->{spec}->{containers}->[0]->{env}->[$i]->{name} = $value;
  $yaml->[@_[3]]->{spec}->{template}->{spec}->{containers}->[0]->{env}->[$i]->{valueFrom}->{secretKeyRef}->{name} = $yaml_secret->[0]->{metadata}->{name};
  $yaml->[@_[3]]->{spec}->{template}->{spec}->{containers}->[0]->{env}->[$i]->{valueFrom}->{secretKeyRef}->{key} = $value;
  $i++;  
  $yaml->write( $dirname . @_[0] );
}
} 

#create format
#format FROMSECRET =
#- name: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  
#$val1
#  valueFrom:
#    secretKeyRef:
#      name: common
#      key: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# $val2   
#.

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
